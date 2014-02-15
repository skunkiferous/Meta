package com.blockwithme.meta.annotations

import com.blockwithme.traits.util.AntiClassLoaderCache
import de.oehme.xtend.contrib.Synchronized
import java.lang.annotation.ElementType
import java.lang.annotation.Retention
import java.lang.annotation.RetentionPolicy
import java.lang.annotation.Target
import java.util.List
import org.eclipse.xtend.core.macro.declaration.CompilationUnitImpl
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.CodeGenerationContext
import org.eclipse.xtend.lib.macro.CodeGenerationParticipant
import org.eclipse.xtend.lib.macro.RegisterGlobalsContext
import org.eclipse.xtend.lib.macro.RegisterGlobalsParticipant
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.TransformationParticipant
import org.eclipse.xtend.lib.macro.declaration.Element
import org.eclipse.xtend.lib.macro.declaration.MutableNamedElement
import org.eclipse.xtend.lib.macro.declaration.MutableTypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.NamedElement
import org.eclipse.xtend.lib.macro.declaration.TypeDeclaration
import org.eclipse.xtext.xbase.lib.Procedures.Procedure3
import java.util.HashMap
import java.util.Map

/**
 * Marks that *all types in this file* should be processed.
 *
 * @author monster
 */
@Active(MagicAnnotationProcessor)
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.CLASS)
annotation Magic {
}

/**
 * Process classes annotated with @Magic
 *
 * @author monster
 */
class MagicAnnotationProcessor implements RegisterGlobalsParticipant<NamedElement>,
CodeGenerationParticipant<NamedElement>, TransformationParticipant<MutableNamedElement> {

	/** Cache key for the processor names */
	static val String PROCESSORS_NAMES = "PROCESSORS_NAMES"

	/** File containing the processor names */
	static val String PROCESSORS_NAMES_FILE = "META-INF/services/"+Processor.name

	/** The processors */
	static var Processor<?,?>[] PROCESSORS

	static val processorUtil = new ProcessorUtil

	private def <TD extends TypeDeclaration> void loop(
		// Somehow, some of my code is executed *outside* of the active annotation processor
		// hook methods, and that code needs the cached state, so I cannot clear the cache
		// at the end of this method.
		// Example:
		//java.lang.NullPointerException
		//	at com.blockwithme.meta.annotations.TraitProcessor.isFunctor(TraitProcessor.java:127)
		//	at com.blockwithme.meta.annotations.TraitProcessor.access$3(TraitProcessor.java:125)
		//	at com.blockwithme.meta.annotations.TraitProcessor$12$1.compile(TraitProcessor.java:1130)
		//	at org.eclipse.xtend.core.macro.declaration.CompilationUnitImpl$18.apply(CompilationUnitImpl.java:981)

		List<? extends NamedElement> annotatedSourceElements,
		String phase, Procedure3<Map<String,Object>, Processor, TD> lambda) {
		val compilationUnit = ProcessorUtil.getCompilationUnit(annotatedSourceElements)
		if (compilationUnit !== null) {
			// Must be called first, for logging correctly
			processorUtil.setElement(phase, annotatedSourceElements.get(0))
			// Manage "persistent" cache
			val pathName = compilationUnit.filePath.toString
			val register = ("register" == phase)
			val transform = ("transform" == phase)
			val generate = ("generate" == phase)
			if (!register) {
				AntiClassLoaderCache.clear(pathName+".register.")
			}
			if (!transform) {
				AntiClassLoaderCache.clear(pathName+".transform.")
			}
			if (!generate) {
				AntiClassLoaderCache.clear(pathName+".generate.")
			}
			val cache = AntiClassLoaderCache.getCache()
			// Lookup processors
			val processors = getProcessors(annotatedSourceElements)
			val allProcessors = newArrayList(processors)
			// Extract types to process from compilation unit (file)
			val allTypes = (if (transform) processorUtil.allMutableTypes else processorUtil.allXtendTypes).toList
			val types = allTypes.toArray(<TypeDeclaration>newArrayOfSize(allTypes.size))
			val todoTypes = newArrayList(types)
			val doneTypes = <TypeDeclaration>newArrayList()
			processorUtil.debug(MagicAnnotationProcessor, "loop", null,
					"Top-Level Types: "+ProcessorUtil.qualifiedNames(types))
			val processingContext = new HashMap<String,Object>()
			processingContext.put(Processor.PC_ALL_FILE_TYPES, allTypes)
			processingContext.put(Processor.PC_TODO_TYPES, todoTypes)
			processingContext.put(Processor.PC_DONE_TYPES, doneTypes)
			processingContext.put(Processor.PC_ALL_PROCESSORS, allProcessors)
			// Process all types
			for (td : types) {
				processingContext.put(Processor.PC_PROCESSED_TYPE, td)
				todoTypes.remove(td)
				val todoProcessors = newArrayList(processors)
				val doneProcessors = <Processor>newArrayList()
				processingContext.put(Processor.PC_TODO_PROCESSORS, todoProcessors)
				processingContext.put(Processor.PC_DONE_PROCESSORS, doneProcessors)
				// Do not process type more then once per phase
				// (THAT is the main reason for the "persistent" cache)
				val unprocessed = (cache.put(pathName+"."+phase+"."+td.qualifiedName, "") === null) || register
				processorUtil.debug(MagicAnnotationProcessor, "loop", td,
					td.qualifiedName+" UNPROCESSED: "+unprocessed)
				if (unprocessed) {
					// If unprocessed (for this phase), check all processors
					for (p : processors) {
						todoProcessors.remove(p)
						processingContext.put(Processor.PC_CURRENT_PROCESSOR, p)
						p.setProcessorUtil(processorUtil)
						try {
							// Check if the processor is interested
							if (p.accept(processingContext, td)) {
								processorUtil.debug(MagicAnnotationProcessor, "loop", td,
										"Calling: "+p+"."+phase+"("+td.qualifiedName+")")
								// Yes? Then call processor.
								lambda.apply(processingContext, p, td as TD)
							} else {
								processorUtil.debug(MagicAnnotationProcessor, "loop", td,
										"NOT Calling: "+p+"."+phase+"("+td.qualifiedName+")")
							}
						} catch (Throwable t) {
							processorUtil.error(MagicAnnotationProcessor, "loop", td, p+": "
								+td.qualifiedName, t)
						} finally {
							// Causes error due to "delayed" method compilation
//							p.setProcessorUtil(null)
						}
						doneProcessors.add(p)
					}
				}
				doneTypes.add(td)
			}
			// Causes error due to "delayed" method compilation
//			processorUtil.setElement(phase, null)
		}
	}

	/** Implements the doRegisterGlobals() phase */
	override void doRegisterGlobals(List<? extends NamedElement> annotatedSourceElements,
			extension RegisterGlobalsContext context) {
		<TypeDeclaration>loop(annotatedSourceElements, "register",
			[processingContext,p,td|p.register(processingContext, td, context)])
	}

	/** Implements the doGenerateCode() phase */
	override doGenerateCode(List<? extends NamedElement> annotatedSourceElements,
			extension CodeGenerationContext context) {
		<TypeDeclaration>loop(annotatedSourceElements, "generate",
			[processingContext,p,td|p.generate(processingContext, td, context)])
	}

	/** Implements the doTransform() phase */
	override doTransform(List<? extends MutableNamedElement> annotatedSourceElements,
			extension TransformationContext context) {
		<MutableTypeDeclaration>loop(annotatedSourceElements, "transform",
			[processingContext,p,mtd|p.transform(processingContext, mtd, context)])
	}

	/** Returns the list of processors. */
	@Synchronized
	private static def Processor<?,?>[] getProcessors(
		List<? extends NamedElement> annotatedSourceElements) {
		val cache = AntiClassLoaderCache.getCache()
		if (PROCESSORS === null) {
			val list = <Processor>newArrayList()
			val compilationUnit = ProcessorUtil.getCompilationUnit(annotatedSourceElements)
			val element = annotatedSourceElements.get(0)
			var String[] names = cache.get(PROCESSORS_NAMES) as String[]
			if (names === null) {
				names = findProcessorNames(compilationUnit, element)
				cache.put(PROCESSORS_NAMES, names)
			}
			for (name : names) {
				try {
					list.add(Class.forName(name).newInstance as Processor<?,?>)
				} catch(Exception ex) {
					processorUtil.error(MagicAnnotationProcessor, "getProcessors", null,
						"Could not instantiate processor for '"+name+"'",ex)
				}
			}
//			for (p : Loader.load(Processor, MagicAnnotationProcessor.classLoader)) {
//				list.add(p)
//			}
			PROCESSORS = list.toArray(<Processor>newArrayOfSize(list.size))
			if (PROCESSORS.length === 0) {
				processorUtil.error(MagicAnnotationProcessor, "getProcessors", null,
					"No processor defined.")
			}
		}
		PROCESSORS
	}

	/** Returns the list of processor names */
	private static def String[] findProcessorNames(
		CompilationUnitImpl compilationUnit, Element element) {
		val list = <String>newArrayList()
		val root = compilationUnit.fileLocations.getProjectFolder(compilationUnit.filePath)
		val file = root.append(PROCESSORS_NAMES_FILE)
		if (compilationUnit.fileSystemSupport.exists(file)) {
			try {
				val content = compilationUnit.fileSystemSupport.getContents(file)
				val buf = new StringBuilder(content.length())
				buf.append(content)
				for (s : buf.toString.split("\n")) {
					val str = s.trim
					if (!str.empty) {
						list.add(str)
					}
				}
				if (list.empty) {
					processorUtil.warn(MagicAnnotationProcessor, "findProcessorNames", null,
						"Could not find processors in '"+file+"'")
				} else {
					// Test values once:
					for (name : list.toArray(newArrayOfSize(list.size))) {
						try {
							// We test both the type and the ability to create them
							if (!(Class.forName(name).newInstance instanceof Processor)) {
								throw new ClassCastException(name+" is not a "+Processor.name)
							}
						} catch(Exception ex) {
							processorUtil.error(MagicAnnotationProcessor, "findProcessorNames", null,
								"Could not instantiate processor for '"+name+"'",ex)
							list.remove(name)
						}
					}
					processorUtil.warn(MagicAnnotationProcessor, "findProcessorNames", null,
						"Processors found in file '"+file+"': "+list)
				}
			} catch(Exception ex) {
				processorUtil.error(MagicAnnotationProcessor, "findProcessorNames", null,
					"Could not read/process '"+file+"'",ex)
			}
		} else {
			processorUtil.warn(MagicAnnotationProcessor, "findProcessorNames", null,
				"Could not find file '"+file+"'")
		}
		list.toArray(newArrayOfSize(list.size))
	}
}
