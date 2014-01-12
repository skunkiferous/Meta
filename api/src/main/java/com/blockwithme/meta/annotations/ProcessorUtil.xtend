/*
 * Copyright (C) 2013 Sebastien Diot.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.blockwithme.meta.annotations

import com.blockwithme.fn.util.Functor
import com.blockwithme.traits.util.AntiClassLoaderCache
import java.io.PrintWriter
import java.io.StringWriter
import java.lang.annotation.Annotation
import java.text.SimpleDateFormat
import java.util.Arrays
import java.util.Collections
import java.util.Date
import java.util.HashMap
import java.util.List
import java.util.Map
import java.util.Objects
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtend.core.macro.declaration.AbstractElementImpl
import org.eclipse.xtend.core.macro.declaration.CompilationUnitImpl
import org.eclipse.xtend.core.macro.declaration.ExpressionImpl
import org.eclipse.xtend.core.xtend.XtendConstructor
import org.eclipse.xtend.core.xtend.XtendEnumLiteral
import org.eclipse.xtend.core.xtend.XtendField
import org.eclipse.xtend.core.xtend.XtendFunction
import org.eclipse.xtend.core.xtend.XtendMember
import org.eclipse.xtend.core.xtend.XtendTypeDeclaration
import org.eclipse.xtend.core.xtend.impl.XtendVariableDeclarationImpl
import org.eclipse.xtend.lib.macro.declaration.AnnotationReference
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.CompilationUnit
import org.eclipse.xtend.lib.macro.declaration.ConstructorDeclaration
import org.eclipse.xtend.lib.macro.declaration.Element
import org.eclipse.xtend.lib.macro.declaration.EnumerationTypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.ExecutableDeclaration
import org.eclipse.xtend.lib.macro.declaration.FieldDeclaration
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MemberDeclaration
import org.eclipse.xtend.lib.macro.declaration.MethodDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableConstructorDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableInterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableMethodDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableTypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.NamedElement
import org.eclipse.xtend.lib.macro.declaration.ParameterDeclaration
import org.eclipse.xtend.lib.macro.declaration.Type
import org.eclipse.xtend.lib.macro.declaration.TypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeParameterDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import org.eclipse.xtend.lib.macro.services.ProblemSupport
import org.eclipse.xtend.lib.macro.services.Tracability
import org.eclipse.xtend.lib.macro.services.TypeReferenceProvider
import org.eclipse.xtext.common.types.JvmDeclaredType
import org.eclipse.xtext.common.types.JvmType
import org.eclipse.xtext.common.types.impl.JvmGenericTypeImpl
import org.eclipse.xtext.xbase.XBlockExpression
import org.eclipse.xtext.xbase.lib.Functions.Function1

/**
 * Helper methods for active annotation processing.
 *
 * @author monster
 */
class ProcessorUtil implements TypeReferenceProvider {
	static val TIME_FORMAT = new SimpleDateFormat("HH:mm:ss.SSS ")

	/** Debug output? */
	private static val DEBUG = true

	/**
	 * The processed NamedElement
	 * (According to the Active Annotation API... We don't care
	 * about it, but we are forced to use it to do logging)
	 */
	var NamedElement element

	/** The ProblemSupport, for logging */
	var ProblemSupport problemSupport

	/** The CompilationUnitImpl that is the "cache key" */
	var CompilationUnitImpl compilationUnit

	/** The processed file */
	var String file

	/** The phase */
	var String phase

	/** A default prefix for cache get/put. */
	var String prefix

	/** The anti-class-loader cache */
	var Map<String,Object> cache

	/** The Functor TypeReference */
	var TypeReference functor

	/** The List TypeReference */
	var TypeReference list

	/** The Arrays TypeReference */
	var TypeReference arrays

	/** The Objects TypeReference */
	var TypeReference objects

	/** The Override Annotation type */
	var Type _override


	/** The type cache */
	val types = new HashMap<String,TypeDeclaration>

	/** The direct parent cache */
	val directParents = new HashMap<TypeDeclaration,Iterable<? extends TypeDeclaration>>

	/** The parent cache */
	val parents = new HashMap<TypeDeclaration,Iterable<? extends TypeDeclaration>>

	/** The JvmDeclaredTypes cache */
	var Iterable<? extends MutableTypeDeclaration> jvmDeclaredTypes

	/** The XtendTypeDeclarations cache */
	var Iterable<? extends TypeDeclaration> xtendTypeDeclarations

	/** Sets the NamedElement currently being processed. */
	package final def void setElement(String phase, NamedElement element) {
		this.phase = phase
		if (this.element !== element) {
			this.element = element
			val before = compilationUnit
			if (element !== null) {
				compilationUnit = element.compilationUnit as CompilationUnitImpl
			} else {
				compilationUnit = null
			}
			if (before !== compilationUnit) {
				types.clear()
				directParents.clear()
				parents.clear()
				jvmDeclaredTypes = null
				xtendTypeDeclarations = null
				if (element != null) {
					problemSupport = compilationUnit.problemSupport
					file = compilationUnit.filePath.toString
					cache = AntiClassLoaderCache.getCache()
					prefix = file+"/"+element.qualifiedName+"/"
					val typeReferenceProvider = compilationUnit.typeReferenceProvider
					functor = typeReferenceProvider.newTypeReference(Functor)
					list = typeReferenceProvider.newTypeReference(List)
					arrays = typeReferenceProvider.newTypeReference(Arrays)
					objects = typeReferenceProvider.newTypeReference(Objects)
					_override = compilationUnit.typeLookup.findTypeGlobally(Override)
				} else {
					problemSupport = null
					file = null
					cache = null
					prefix = null
					functor = null
					list = null
					arrays = null
					objects = null
					_override = null
				}
			}
		}
	}

	/** Returns a String version of the current time. */
	private static def time() {
		TIME_FORMAT.format(new Date())
	}

	/** Returns the CompilationUnit of those elements */
	static def CompilationUnitImpl getCompilationUnit(
		List<? extends NamedElement> annotatedSourceElements) {
		if (!annotatedSourceElements.empty) {
			val element = annotatedSourceElements.get(0)
			return element.compilationUnit as CompilationUnitImpl
		}
		null
	}

	/** The CompilationUnitImpl that is the "cache key" */
	final def getCompilationUnit() {
		compilationUnit
	}

	/** The processed file */
	final def getFile() {
		file
	}

	/** The anti-class-loader cache */
	final def getCache() {
		cache
	}

	/** The phase */
	final def getPhase() {
		phase
	}

	/** Returns the top-level Xtend types of this CompilationUnit */
	final def Iterable<? extends TypeDeclaration> getXtendTypes() {
		if (xtendTypeDeclarations === null) {
			xtendTypeDeclarations = compilationUnit.xtendFile.xtendTypes
				.map[compilationUnit.toXtendTypeDeclaration(it)]
		}
		xtendTypeDeclarations
	}

	/** Returns the top-level mutable types of this CompilationUnit */
	final def Iterable<? extends MutableTypeDeclaration> getMutableTypes() {
		if (jvmDeclaredTypes === null) {
			jvmDeclaredTypes = compilationUnit.xtendFile.eResource.contents
				.filter(JvmDeclaredType).map[compilationUnit.toTypeDeclaration(it)]
		}
		jvmDeclaredTypes
	}

	/** Recursively returns the Xtend types of this CompilationUnit */
	final def Iterable<? extends TypeDeclaration> getAllXtendTypes() {
		doRecursivelyN(getXtendTypes()) [
			(it.declaredClasses + it.declaredInterfaces) as Iterable<? extends TypeDeclaration>
		]
	}

	/** Recursively returns the top-level mutable types of this CompilationUnit */
	final def Iterable<? extends MutableTypeDeclaration> getAllMutableTypes() {
		doRecursivelyN(getMutableTypes()) [
			(it.declaredClasses + it.declaredInterfaces) as Iterable<? extends TypeDeclaration>
		] as Iterable<? extends MutableTypeDeclaration>
	}

	/** Sometimes, Xtend "forgets" to set the "isInterface" flag on types! */
	private def fixInterface(JvmType type, boolean isInterface) {
		if (type instanceof JvmGenericTypeImpl) {
			// Horrible, horrible hack!
			if (!type.isInterface) {
				type.setInterface(isInterface)
			}
		}
	}

	/**
	 * Lookup a type by name.
	 *
	 * @param td	the type that needs the lookup.
	 * @param isInterface	should the searched-for type be an interface? (Workaround for Xtend issue)
	 * @param typeName	The name of the type we are looking for.
	 */
	private def TypeDeclaration lookup(TypeDeclaration td,
		boolean isInterface, String typeName) {
		var result = types.get(typeName)
		if (result === null) {
			result = lookup2(td, isInterface, typeName)
			types.put(typeName, result)
		}
		result
	}

	/**
	 * Lookup a type by name.
	 *
	 * @param td	the type that needs the lookup.
	 * @param isInterface	should the searched-for type be an interface? (Workaround for Xtend issue)
	 * @param typeName	The name of the type we are looking for.
	 */
	private def TypeDeclaration lookup2(TypeDeclaration td,
		boolean isInterface, String typeName) {
		val compilationUnit = td.compilationUnit as CompilationUnitImpl
		val parentIsJvmType = (td instanceof JvmType)
		if (parentIsJvmType) {
			val tmp = getMutableTypes().findFirst[it.qualifiedName == typeName]
			if (tmp !== null) {
				return tmp
			}
//			if (jvmDeclaredTypes === null) {
//				jvmDeclaredTypes = compilationUnit.xtendFile.eResource.contents.filter(JvmDeclaredType)
//			}
//			for (t : jvmDeclaredTypes) {
//				if (t.qualifiedName == typeName) {
//					fixInterface(t, isInterface)
//					return compilationUnit.toTypeDeclaration(t)
//				}
//			}
		} else {
			val tmp = getXtendTypes().findFirst[it.qualifiedName == typeName]
			if (tmp !== null) {
				return tmp
			}
		}
		// Not found. Maybe it lives outside the file?
		val foreign = compilationUnit.typeReferences.findDeclaredType(typeName, compilationUnit.xtendFile)
		if (foreign == null) {
			// Ouch!
			throw new IllegalStateException("Could not find parent type "+typeName+" of type "+td.qualifiedName)
		} else {
			fixInterface(foreign, isInterface)
			val result = compilationUnit.toType(foreign) as TypeDeclaration
			if (!parentIsJvmType && (result.compilationUnit == compilationUnit)) {
				throw new IllegalStateException("Parent type "+typeName+" of type "+td.qualifiedName
					+" could not be found as Xtend type!")
			}
			result
		}
	}

	/** Converts TypeReferences to TypeDeclarations */
	private def Iterable<? extends TypeDeclaration> convert(
		TypeDeclaration td, boolean isInterface, Iterable<? extends TypeReference> refs) {
		refs.map[lookup(td, isInterface, it.name)]
	}

	/** Returns the direct parents */
	private def Iterable<? extends TypeDeclaration> findDirectParents(TypeDeclaration td) {
		var result = directParents.get(td)
		if (result === null) {
			result = findDirectParents2(td)
			directParents.put(td, result)
		}
		result
	}

	/** Returns the direct parents */
	private dispatch def Iterable<? extends TypeDeclaration> findDirectParents2(TypeDeclaration td) {
		Collections.emptyList
	}

	/** Returns the direct parents */
	private dispatch def Iterable<? extends TypeDeclaration> findDirectParents2(ClassDeclaration td) {
		val result = <TypeDeclaration>newArrayList()
		result.addAll(convert(td, true, td.implementedInterfaces))
		result.addAll(convert(td, false, Collections.singleton(td.extendedClass)))
		result
	}

	/** Returns the direct parents */
	private dispatch def Iterable<? extends TypeDeclaration> findDirectParents2(InterfaceDeclaration td) {
		convert(td, true, td.extendedInterfaces)
	}

	/** Returns the direct parents */
	private dispatch def Iterable<? extends TypeDeclaration> findDirectParents2(EnumerationTypeDeclaration td) {
		// TODO: td.implementedInterfaces is not implemented in EnumerationTypeDeclaration yet!
		Collections.emptyList
	}

	/** Returns the all parents, *including the type itself* */
	final def Iterable<? extends TypeDeclaration> findParents(TypeDeclaration td) {
		var result = parents.get(td)
		if (result === null) {
			result = findParents2(td)
			parents.put(td, result)
		}
		result
	}

	/** Performs some operation recursively on the TypeDeclaration. */
	final def Iterable<TypeDeclaration> doRecursively1(TypeDeclaration td,
		Function1<TypeDeclaration, Iterable<? extends TypeDeclaration>> lambda) {
		doRecursivelyN(Collections.singleton(td), lambda)
	}

	/** Performs some operation recursively on the TypeDeclarations. */
	final def Iterable<TypeDeclaration> doRecursivelyN(
		Iterable<? extends TypeDeclaration> tds,
		Function1<TypeDeclaration, Iterable<? extends TypeDeclaration>> lambda) {
		val todo = <TypeDeclaration>newArrayList()
		val done = <TypeDeclaration>newArrayList()
		todo.addAll(tds)
		while (!todo.empty) {
			val next = todo.remove(todo.size-1)
			done.add(next)
			for (parent : lambda.apply(next)) {
				if (!todo.contains(parent) && !done.contains(parent)) {
					todo.add(parent)
				}
			}
		}
		done
	}

	/** Returns the all parents, *including the type itself* */
	private def Iterable<? extends TypeDeclaration> findParents2(TypeDeclaration td) {
		doRecursively1(td) [ findDirectParents(it) ]
	}

	/** Does the given type directly bares the desired annotation? */
	final def hasDirectAnnotation(TypeDeclaration td, String annotationName) {
		td.annotations.exists[annotationTypeDeclaration.qualifiedName == annotationName]
	}

	/** Does the given type directly bares the desired annotation? */
	final def hasDirectAnnotation(TypeDeclaration td, Class<? extends Annotation> annotation) {
		hasDirectAnnotation(td, annotation.name)
	}

	/** Returns the name, annotations, base class and implemented interfaces of the type (not the content). */
	final def String describeTypeDeclaration(TypeDeclaration td, extension Tracability tracability) {
		Objects.requireNonNull(td, "td")
		val td2 = findXtend(td)
		val aei = td2 as AbstractElementImpl
		'''
		simpleName >> «td2.simpleName»
		toString  >> «td2»
		file  >> «td2.compilationUnit.filePath»
		generated >> «td2.generated»
		source >> «td2.source»
		primaryGeneratedJavaElement >> «td2.primaryGeneratedJavaElement»
		delegate class >> «aei.delegate.class»
		annotations >> «qualifiedNames(td2.annotations)»
		«IF td2 instanceof InterfaceDeclaration»
			implemented interfaces >> «qualifiedNames(td2.extendedInterfaces)»
		«ENDIF»
		«IF td2 instanceof ClassDeclaration»
			«IF td2.extendedClass !== null»
				super >> «td2.extendedClass.name»
			«ENDIF»
			implemented interfaces >> «qualifiedNames(td2.implementedInterfaces)»
		«ENDIF»
		---------------------------------
		«FOR m : td2.declaredMethods»
			«m.describeMethod(tracability)»
			-------------
		«ENDFOR»
		---------------------------------
		«FOR f : td2.declaredFields»
			«f.describeField(tracability)»
			-------------
		«ENDFOR»
		'''
	}

	/** Returns a long trace of all the info of that method. */
	final def String describeMethod(MethodDeclaration m, extension Tracability tracability) {
		Objects.requireNonNull(m, "m")
		val bdy =  m.body as ExpressionImpl
		val method = bdy.delegate as XBlockExpression

		'''
		simpleName >> «m.simpleName»
		signature  >> «signature(m)»
		toString  >> «bdy»
		file  >> «bdy.compilationUnit.filePath»
		generated >> «m.generated»
		source >> «m.source»
		primaryGeneratedJavaElement >> «m.primaryGeneratedJavaElement»
		delegate class >> «bdy.delegate.class»
		annotations >> «qualifiedNames(m.annotations)»
		---------------------------------
		«FOR e : method.expressions»
			expression >> «e»
			expression class>> «e.class»
			«IF e instanceof XtendVariableDeclarationImpl»
				simpleName >> « e.simpleName»
				qualifiedName >> « e.qualifiedName»
				right >> « e.right»
				«IF e.type != null»
					type qualifiedName >> « e.type.qualifiedName»
					type identifier >> « e.type.identifier»
				«ENDIF»
				value >> « e.name»
				-------------------
			«ENDIF»
			-------------
		«ENDFOR»
		'''
	}

	/** Returns a long trace of all the info of that field. */
	final def String describeField(FieldDeclaration f, extension Tracability tracability) {
		Objects.requireNonNull(f, "f")
		val bdy =  f.initializer as ExpressionImpl
		var type = f.type
		if (type === null) {
			type = (f.primaryGeneratedJavaElement as FieldDeclaration).type
		}
		'''
		simpleName >> «f.simpleName»
		type >> «qualifiedName(type)»
		toString  >> «bdy»
		file  >> «bdy.compilationUnit.filePath»
		generated >> «f.generated»
		source >> «f.source»
		primaryGeneratedJavaElement >> «f.primaryGeneratedJavaElement»
		delegate class >> «bdy.delegate.class»
		annotations >> «qualifiedNames(f.annotations)»
		'''
	}

	/** Returns the signature of a method/constructor as a string */
	final def String signature(ExecutableDeclaration it) {
		'''«simpleName»(«parameters.map[p|p.type].join(",")[name]»)'''
	}

	/** Tries to find and return the qualifiedName of the given element. */
	def static dispatch String qualifiedName(Void element) {
		null
	}

	/** Tries to find and return the qualifiedName of the given element. */
	def static dispatch String qualifiedName(Element element) {
		throw new IllegalArgumentException(element.class+" cannot be processed")
	}

	/** Tries to find and return the qualifiedName of the given element. */
	def static dispatch String qualifiedName(TypeReference element) {
		element.name
	}

	/** Tries to find and return the qualifiedName of the given element. */
	def static dispatch String qualifiedName(Type element) {
		element.getQualifiedName()
	}

	/** Tries to find and return the qualifiedName of the given element. */
	def static dispatch String qualifiedName(AnnotationReference element) {
		element.annotationTypeDeclaration.getQualifiedName()
	}

	/** Tries to find and return the qualifiedName of the given element. */
	def static dispatch String qualifiedName(CompilationUnit element) {
		element.getFilePath().toString
	}

	/** Tries to find and return the qualifiedName of the given element. */
	def static dispatch String qualifiedName(MemberDeclaration element) {
		if (element instanceof Type) {
			return element.getQualifiedName()
		}
		Objects.requireNonNull(element.declaringType,element+".declaringType")
		element.declaringType.qualifiedName+"."+element.simpleName
	}

	/** Tries to find and return the qualifiedName of the given element. */
	def static dispatch String qualifiedName(ParameterDeclaration element) {
		Objects.requireNonNull(element.getDeclaringExecutable(),element+".getDeclaringExecutable()")
		element.getDeclaringExecutable().qualifiedName+"."+element.simpleName
	}

	/** Tries to find and return the qualifiedName of the given element. */
	def static dispatch String qualifiedName(TypeParameterDeclaration element) {
		Objects.requireNonNull(element.getTypeParameterDeclarator(),element+".getTypeParameterDeclarator()")
		element.getTypeParameterDeclarator().qualifiedName+"."+element.simpleName
	}

	/** Tries to find and return the qualifiedName of the given element. */
	def static dispatch String qualifiedName(XtendMember element) {
		if (element instanceof XtendTypeDeclaration) {
			return element.getName()
		}
		Objects.requireNonNull(element.declaringType,element+".declaringType")
		element.declaringType.getName()+"."+element.simpleName
	}

	/** Tries to find and return the qualifiedName of the given element. */
	def static String qualifiedNames(Iterable<?> elements) {
		elements.map[qualifiedName].toString
	}

	/** Tries to find and return the simpleName of the given XtendMember. */
	def static dispatch String simpleName(Void element) {
		null
	}

	/** Tries to find and return the simpleName of the given XtendMember. */
	def static dispatch String simpleName(XtendConstructor element) {
		element.declaringType.name
	}

	/** Tries to find and return the simpleName of the given XtendMember. */
	def static dispatch String simpleName(XtendField element) {
		element.name
	}

	/** Tries to find and return the simpleName of the given XtendMember. */
	def static dispatch String simpleName(XtendEnumLiteral element) {
		element.name
	}

	/** Tries to find and return the simpleName of the given XtendMember. */
	def static dispatch String simpleName(XtendFunction element) {
		element.name
	}

	/** Tries to find and return the simpleName of the given XtendMember. */
	def static dispatch String simpleName(XtendTypeDeclaration element) {
		val qualifiedName = element.name
		val char dot = '.'
		val index = qualifiedName.lastIndexOf(dot)
		if (index < 0)
			return qualifiedName
		return qualifiedName.substring(index+1)
	}

	/** Tries to find "non-Xtend" matching type */
	final def TypeDeclaration findNonXtend(TypeDeclaration td) {
		if (td instanceof XtendTypeDeclaration) {
			val name = td.qualifiedName
			val result = mutableTypes.findFirst[qualifiedName == name]
			if (result !== null) {
				return result
			}
		}
		return td
	}

	/** Tries to find Xtend matching type */
	final def TypeDeclaration findXtend(TypeDeclaration td) {
		if (td instanceof MutableTypeDeclaration) {
			val name = td.qualifiedName
			val result = xtendTypes.findFirst[qualifiedName == name]
			if (result !== null) {
				return result
			}
		}
		return td
	}

	/** Builds the standard log message format */
	private def buildMessage(boolean debug, Class<?> who, String where, String message, Throwable t) {
		val phase = if (debug) "DEBUG: "+this.phase else phase
		var msg = message.replaceAll("com.blockwithme.meta.annotations.","cbma.")
			.replaceAll("com.blockwithme.meta.","cbm.")
		if (t != null) {
			msg = msg+"\n"+asString(t)
		}
		ProcessorUtil.time+phase+": "+who.simpleName+"."+where+": "+msg
	}

	/** Returns the element to use when logging */
	private def Element extractLoggingElement(Element what) {
		if ((what !== null) && !(what instanceof CompilationUnit)) {
			if (what instanceof AbstractElementImpl) {
				val element = what as AbstractElementImpl<? extends EObject>
				val resource = element.delegate.eResource
				if (resource == compilationUnit.xtendFile.eResource) {
					return what
				} else {
					// Wrong file!?!
//					throw new IllegalArgumentException("Element.delegate.eResource: "+resource
//						+" Expected: "+compilationUnit.xtendFile.eResource
//					)
					return this.element
				}
			} else if (what instanceof XtendTypeDeclaration) {
				return findNonXtend(what as TypeDeclaration)
			} else {
				throw new IllegalArgumentException("Element type: "+what.class)
			}
		} else {
			element
		}
	}

	/** Converts a Throwable stack-trace to a String */
	final def asString(Throwable t) {
		val sw = new StringWriter()
		t.printStackTrace(new PrintWriter(sw))
		sw.toString
	}

	/**
	 * Records an error for the given element
	 *
	 * @param element the element to which associate the message
	 * @param message the message
	 */
	final def void error(Class<?> who, String where, Element what, String message) {
		val logElem = extractLoggingElement(what)
		problemSupport.addError(logElem, buildMessage(false, who, where, message, null))
	}

	/**
	 * Records an error for the given element
	 *
	 * @param element the element to which associate the message
	 * @param message the message
	 */
	final def void error(Class<?> who, String where, Element what, String message, Throwable t) {
		val logElem = extractLoggingElement(what)
		problemSupport.addError(logElem, buildMessage(false, who, where, message, t))
	}

	/**
	 * Records a warning for the given element
	 *
	 * @param element the element to which associate the message
	 * @param message the message
	 */
	final def void warn(Class<?> who, String where, Element what, String message) {
		val logElem = extractLoggingElement(what)
		problemSupport.addWarning(logElem, buildMessage(false, who, where, message, null))
	}

	/**
	 * Records a warning for the given element
	 *
	 * @param element the element to which associate the message
	 * @param message the message
	 */
	final def void warn(Class<?> who, String where, Element what, String message, Throwable t) {
		val logElem = extractLoggingElement(what)
		problemSupport.addWarning(logElem, buildMessage(false, who, where, message, t))
	}

	/**
	 * Records a warning for the given element
	 *
	 * @param element the element to which associate the message
	 * @param message the message
	 */
	final def void debug(Class<?> who, String where, Element what, String message) {
		if (DEBUG) {
			val logElem = extractLoggingElement(what)
			problemSupport.addWarning(logElem, buildMessage(true, who, where, message, null))
		}
	}

	/**
	 * Records a warning for the given element
	 *
	 * @param element the element to which associate the message
	 * @param message the message
	 */
	final def void debug(Class<?> who, String where, Element what, String message, Throwable t) {
		if (DEBUG) {
			val logElem = extractLoggingElement(what)
			problemSupport.addWarning(logElem, buildMessage(true, who, where, message, t))
		}
	}

	/** Reads from the cache, using a specified prefix. */
	final def Object get(String prefix, String key) {
		cache.get(prefix+key)
	}

	/** Writes to the cache, using a specified prefix. */
	final def Object put(String prefix, String key, Object newValue) {
		if (newValue === null) {
			cache.remove(prefix+key)
		} else {
			cache.put(prefix+key, newValue)
		}
	}

	/** Reads from the cache, using the default prefix. */
	final def Object get(String key) {
		cache.get(prefix+key)
	}

	/** Writes to the cache, using the default prefix. */
	final def Object put(String key, Object newValue) {
		if (newValue === null) {
			cache.remove(prefix+key)
		} else {
			cache.put(prefix+key, newValue)
		}
	}

	/** Returns true, if the given element is a marker interface */
	final def boolean isMarker(Element element) {
		if (element instanceof InterfaceDeclaration) {
			for (parent : findParents(element)) {
				if (parent != element) {
					if (!isMarker(parent)) {
						return false
					}
				}
			}
			return true
		}
		if (element instanceof TypeReference) {
			return isMarker(element.getType())
		}
		false
	}

	final def Type findTypeGlobally(Class<?> type) {
		compilationUnit.typeLookup.findTypeGlobally(type)
	}

	final def Type findTypeGlobally(String typeName) {
		compilationUnit.typeLookup.findTypeGlobally(typeName)
	}

	/** Utility method that finds an interface in the global context, returns null if not found */
	def findInterface(String name) {
		val found = findTypeGlobally(name)
		if (found instanceof MutableInterfaceDeclaration)
			found as MutableInterfaceDeclaration
		else
			null
	}

	/** Utility method that finds a class in the global context, returns null if not found */
	def findClass(String name) {
		val found = findTypeGlobally(name)
		if (found instanceof MutableClassDeclaration)
			found as MutableClassDeclaration
		else
			null
	}

	/** Searches for the *default* constructor. */
	final def ConstructorDeclaration findConstructor(TypeDeclaration clazz) {
		for (c : clazz.declaredConstructors) {
			if (c.parameters.isEmpty) {
				return c
			}
		}
		null
	}

	/** Searches for the *default* constructor. */
	final def MutableConstructorDeclaration findConstructor(MutableClassDeclaration clazz) {
		findConstructor(clazz as TypeDeclaration) as MutableConstructorDeclaration
	}

	/** Searches for the method with the given name and parameters. */
	final def MethodDeclaration findMethod(TypeDeclaration clazz,
		String name, TypeReference ... parameterTypes) {
		val tmp = parameterTypes.toList
		for (m : clazz.declaredMethods) {
			if ((m.simpleName == name) && (m.parameters.toList == tmp)) {
				return m
			}
		}
		null
	}

	/** Searches for the method with the given name and parameters. */
	final def MutableMethodDeclaration findMethod(MutableClassDeclaration clazz,
		String name, TypeReference ... parameterTypes) {
		findMethod(clazz as TypeDeclaration, name, parameterTypes) as MutableMethodDeclaration
	}

	/** The Functor TypeReference */
	final def getFunctor() {
		functor
	}

	/** The List TypeReference */
	final def getList() {
		list
	}

	/** The Arrays TypeReference */
	final def getArrays() {
		arrays
	}

	/** The Objects TypeReference */
	final def getObjects() {
		objects
	}

	/** The Override Annotation Type */
	final def getOverride() {
		_override
	}

	override getAnyType() {
		compilationUnit.typeReferenceProvider.getAnyType()
	}

	override getList(TypeReference param) {
		compilationUnit.typeReferenceProvider.getList(param)
	}

	override getObject() {
		compilationUnit.typeReferenceProvider.getObject()
	}

	override getPrimitiveBoolean() {
		compilationUnit.typeReferenceProvider.getPrimitiveBoolean()
	}

	override getPrimitiveByte() {
		compilationUnit.typeReferenceProvider.getPrimitiveByte()
	}

	override getPrimitiveChar() {
		compilationUnit.typeReferenceProvider.getPrimitiveChar()
	}

	override getPrimitiveDouble() {
		compilationUnit.typeReferenceProvider.getPrimitiveDouble()
	}

	override getPrimitiveFloat() {
		compilationUnit.typeReferenceProvider.getPrimitiveFloat()
	}

	override getPrimitiveInt() {
		compilationUnit.typeReferenceProvider.getPrimitiveInt()
	}

	override getPrimitiveLong() {
		compilationUnit.typeReferenceProvider.getPrimitiveLong()
	}

	override getPrimitiveShort() {
		compilationUnit.typeReferenceProvider.getPrimitiveShort()
	}

	override getPrimitiveVoid() {
		compilationUnit.typeReferenceProvider.getPrimitiveVoid()
	}

	override getSet(TypeReference param) {
		compilationUnit.typeReferenceProvider.getSet(param)
	}

	override getString() {
		compilationUnit.typeReferenceProvider.getString()
	}

	override newArrayTypeReference(TypeReference componentType) {
		compilationUnit.typeReferenceProvider.newArrayTypeReference(componentType)
	}

	override newTypeReference(String typeName, TypeReference... typeArguments) {
		compilationUnit.typeReferenceProvider.newTypeReference(typeName, typeArguments)
	}

	override newTypeReference(Type typeDeclaration, TypeReference... typeArguments) {
		compilationUnit.typeReferenceProvider.newTypeReference(typeDeclaration, typeArguments)
	}

	override newTypeReference(Class<?> clazz, TypeReference... typeArguments) {
		compilationUnit.typeReferenceProvider.newTypeReference(clazz, typeArguments)
	}

	override newWildcardTypeReference() {
		compilationUnit.typeReferenceProvider.newWildcardTypeReference()
	}

	override newWildcardTypeReference(TypeReference upperBound) {
		compilationUnit.typeReferenceProvider.newWildcardTypeReference(upperBound)
	}

	override newWildcardTypeReferenceWithLowerBound(TypeReference lowerBound) {
		compilationUnit.typeReferenceProvider.newWildcardTypeReferenceWithLowerBound(lowerBound)
	}

}