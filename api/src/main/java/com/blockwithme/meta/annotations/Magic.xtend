package com.blockwithme.meta.annotations

import com.blockwithme.traits.util.AntiClassLoaderCache
import de.oehme.xtend.contrib.Synchronized
import java.io.PrintWriter
import java.io.StringWriter
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
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.Element
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableTypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeDeclaration
import org.eclipse.xtext.xbase.lib.Procedures.Procedure3
import org.eclipse.xtext.xbase.lib.Procedures.Procedure2
import org.eclipse.xtend.lib.macro.declaration.NamedElement
import org.eclipse.xtend.lib.macro.declaration.MutableNamedElement

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
	static val String PROCESSORS_NAMES_FILE = "magic.processor.names.txt"

	/** The processors */
	static var Processor<?,?>[] PROCESSORS

	static val processorUtil = new ProcessorUtil

	private static def onError(String phase, Throwable t, TypeDeclaration td,
		Processor<?,?> p, CompilationUnitImpl compilationUnit) {
		val sw = new StringWriter()
		sw.append(p.toString).append(": ").append(phase).append("(").append(td.qualifiedName).append("): Error!\n ")
		sw.append("annotations: ").append(td.annotations.toList.toString)
		if (td instanceof InterfaceDeclaration) {
			sw.append(", interfaces: ").append(td.extendedInterfaces.toList.toString).append("\n")
		}
		if (td instanceof ClassDeclaration) {
			sw.append(", interfaces: ").append(td.implementedInterfaces.toList.toString).append("\n")
		}
		sw.append("\n ")
		t.printStackTrace(new PrintWriter(sw))
		compilationUnit.problemSupport.addError(td, ProcessorUtil.time()+sw.toString)
	}

	private def <TD extends TypeDeclaration> void loop(
		List<? extends NamedElement> annotatedSourceElements,
		String phase, Procedure2<Processor, TD> lambda) {
		val compilationUnit = ProcessorUtil.getCompilationUnit(annotatedSourceElements)
		if (compilationUnit !== null) {
			val pathName = compilationUnit.filePath.toString
			val problemSupport = compilationUnit.problemSupport
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
			val processors = getProcessors(annotatedSourceElements)
			processorUtil.setElement(phase, annotatedSourceElements.get(0))
			val types = if (transform) processorUtil.mutableTypes else processorUtil.xtendTypes
			if (ProcessorUtil.DEBUG) {
				problemSupport.addWarning(annotatedSourceElements.get(0),
					ProcessorUtil.time()+"FILE: "+pathName+" PHASE: "+phase+" TYPES: "+types.toList)
			}
			for (mtd : types) {
				processorUtil.setElement(phase, mtd)
				val unprocessed = (cache.put(pathName+"."+phase+"."+mtd.qualifiedName, "") === null)
				if (ProcessorUtil.DEBUG) {
					problemSupport.addWarning(annotatedSourceElements.get(0),
						ProcessorUtil.time()+"PHASE: "+phase+" TYPE: "+mtd+" UNPROCESSED: "+unprocessed)
				}
				if (unprocessed) {
					for (p : processors) {
						p.setProcessorUtil(processorUtil)
						try {
							if (p.accept(mtd)) {
								if (ProcessorUtil.DEBUG) {
									problemSupport.addWarning(mtd,
										ProcessorUtil.time()+p+": "+phase+"("+mtd.qualifiedName+") => OK")
								}
								lambda.apply(p, mtd as TD)
							} else if (ProcessorUtil.DEBUG) {
								problemSupport.addWarning(mtd,
									ProcessorUtil.time()+p+": "+phase+"("+mtd.qualifiedName+") => REJECTED")
							}
						} catch (Throwable t) {
							onError(phase, t, mtd, p, compilationUnit)
						} finally {
							p.setProcessorUtil(null)
						}
					}
				}
			}
			processorUtil.setElement(phase, null)
		}
	}

	override doRegisterGlobals(List<? extends NamedElement> annotatedSourceElements,
			extension RegisterGlobalsContext context) {
		<TypeDeclaration>loop(annotatedSourceElements, "register",
			[p,td|p.register(td, context)])
	}

	override doGenerateCode(List<? extends NamedElement> annotatedSourceElements,
			extension CodeGenerationContext context) {
		<TypeDeclaration>loop(annotatedSourceElements, "generate",
			[p,td|p.generate(td, context)])
	}

	override doTransform(List<? extends MutableNamedElement> annotatedSourceElements,
			extension TransformationContext context) {
		<MutableTypeDeclaration>loop(annotatedSourceElements, "transform",
			[p,mtd|p.transform(mtd, context)])
	}

	/** Returns the list of processors. */
	@Synchronized
	private static def Processor<?,?>[] getProcessors(
		List<? extends NamedElement> annotatedSourceElements) {
		val cache = AntiClassLoaderCache.getCache()
		if (PROCESSORS === null) {
			val compilationUnit = ProcessorUtil.getCompilationUnit(annotatedSourceElements)
			val element = annotatedSourceElements.get(0)
			var String[] names = cache.get(PROCESSORS_NAMES) as String[]
			if (names === null) {
				names = findProcessorNames(compilationUnit, element)
				cache.put(PROCESSORS_NAMES, names)
			}
			val list = <Processor>newArrayList()
			for (name : names) {
				try {
					list.add(Class.forName(name).newInstance as Processor<?,?>)
				} catch(Exception ex) {
					compilationUnit.problemSupport.addError(element,
						ProcessorUtil.time()+"Could not instantiate processor for '"+name+"': "+ex)
				}
			}
			PROCESSORS = list.toArray(<Processor>newArrayOfSize(list.size))
			if (PROCESSORS.length === 0) {
				compilationUnit.problemSupport.addWarning(element,
					ProcessorUtil.time()+"No processor defined.")
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
				for (s : buf.toString.split(":")) {
					val str = s.trim
					if (!str.empty) {
						list.add(str)
					}
				}
				if (list.empty) {
					compilationUnit.problemSupport.addWarning(element,
						ProcessorUtil.time()+"Could not find processors in '"+file+"'")
				} else {
					// Test values once:
					for (name : list.toArray(newArrayOfSize(list.size))) {
						try {
							// We test both the type and the ability to create them
							if (!(Class.forName(name).newInstance instanceof Processor)) {
								throw new ClassCastException(name+" is not a "+Processor.name)
							}
						} catch(Exception ex) {
							compilationUnit.problemSupport.addError(element,
								ProcessorUtil.time()+"Could not instantiate processor for '"+name+"': "+ex)
							list.remove(name)
						}
					}
					compilationUnit.problemSupport.addWarning(element,
						ProcessorUtil.time()+"Processors found in file '"+file+"': "+list)
				}
			} catch(Exception ex) {
				compilationUnit.problemSupport.addError(element,
					ProcessorUtil.time()+"Could not read/process '"+file+"': "+ex)
			}
		} else {
			compilationUnit.problemSupport.addWarning(element,
				ProcessorUtil.time()+"Could not find file '"+file+"'")
		}
		list.toArray(newArrayOfSize(list.size))
	}
}
