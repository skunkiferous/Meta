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
import java.lang.annotation.Annotation
import java.text.SimpleDateFormat
import java.util.Arrays
import java.util.Collections
import java.util.Date
import java.util.HashMap
import java.util.List
import java.util.Map
import java.util.Objects
import org.eclipse.xtend.core.macro.declaration.CompilationUnitImpl
import org.eclipse.xtend.core.macro.declaration.ExpressionImpl
import org.eclipse.xtend.core.xtend.impl.XtendVariableDeclarationImpl
import org.eclipse.xtend.lib.macro.declaration.AnnotationReference
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.CompilationUnit
import org.eclipse.xtend.lib.macro.declaration.ConstructorDeclaration
import org.eclipse.xtend.lib.macro.declaration.Element
import org.eclipse.xtend.lib.macro.declaration.EnumerationTypeDeclaration
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
import org.eclipse.xtext.common.types.JvmDeclaredType
import org.eclipse.xtext.common.types.JvmType
import org.eclipse.xtext.common.types.impl.JvmGenericTypeImpl
import org.eclipse.xtext.xbase.XBlockExpression

/**
 * Helper methods for active annotation processing.
 *
 * @author monster
 */
class ProcessorUtil {
	static val TIME_FORMAT = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS ")

	/** Debug output? */
	public static val DEBUG = false

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
	static def time() {
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

	/** Returns the Xtend types of this CompilationUnit */
	final def Iterable<? extends TypeDeclaration> getXtendTypes() {
		if (xtendTypeDeclarations === null) {
			xtendTypeDeclarations = compilationUnit.xtendFile.xtendTypes
				.map[compilationUnit.toXtendTypeDeclaration(it)]
		}
		xtendTypeDeclarations
	}

	/** Returns the mutable types of this CompilationUnit */
	final def Iterable<? extends MutableTypeDeclaration> getMutableTypes() {
		if (jvmDeclaredTypes === null) {
			jvmDeclaredTypes = compilationUnit.xtendFile.eResource.contents
				.filter(JvmDeclaredType).map[compilationUnit.toTypeDeclaration(it)]
		}
		jvmDeclaredTypes
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

	/** Returns the all parents, *including the type itself* */
	private def Iterable<? extends TypeDeclaration> findParents2(TypeDeclaration td) {
		val todo = <TypeDeclaration>newArrayList()
		val done = <TypeDeclaration>newArrayList()
		todo.add(td)
		while (!todo.empty) {
			val next = todo.remove(todo.size-1)
			done.add(next)
			for (parent : findDirectParents(td)) {
				if (!todo.contains(parent) && !done.contains(parent)) {
					todo.add(parent)
				}
			}
		}
		done
	}

	/** Does the given type directly bares the desired annotation? */
	final def hasDirectAnnotation(TypeDeclaration td, String annotationName) {
		td.annotations.exists[annotationTypeDeclaration.qualifiedName == annotationName]
	}

	/** Does the given type directly bares the desired annotation? */
	final def hasDirectAnnotation(TypeDeclaration td, Class<? extends Annotation> annotation) {
		hasDirectAnnotation(td, annotation.name)
	}

	/** Returns a long trace of all the info of that method. */
	final def String describeMethod(MethodDeclaration m, extension Tracability tracability) {
		val bdy =  m.body as ExpressionImpl
		val method = bdy.delegate as XBlockExpression

		'''
		toString  >> «bdy»
		toString2  >> «bdy.compilationUnit.toString»
		generated >> «bdy.compilationUnit.generated»
		source >> «bdy.compilationUnit.source»
		primaryGeneratedJavaElement >> «bdy.compilationUnit.primaryGeneratedJavaElement»
		simpleName >> «bdy.compilationUnit.simpleName»
		delegate class >> «bdy.delegate.class»
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

	/**
	 * Records an error for the given element
	 *
	 * @param element the element to which associate the message
	 * @param message the message
	 */
	final def void error(Element element, String message) {
		problemSupport.addError(element, ProcessorUtil.time+message)
	}

	/**
	 * Records a warning for the given element
	 *
	 * @param element the element to which associate the message
	 * @param message the message
	 */
	final def void warn(Element element, String message) {
		problemSupport.addWarning(element, ProcessorUtil.time+message)
	}

	/**
	 * Records a warning for the currently processed type
	 *
	 * @param message the message
	 */
	final def void warn(String message) {
		problemSupport.addWarning(element, ProcessorUtil.time+message)
	}

	/**
	 * Records an error for the currently processed type
	 *
	 * @param message the message
	 */
	final def void error(String message) {
		problemSupport.addError(element, ProcessorUtil.time+message)
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

	/** Returns true, if the given element is a marker interface */
	final def boolean isMarker(Element element) {
		if (element instanceof InterfaceDeclaration) {
			for (parent : findParents(element)) {
				if (!isMarker(parent)) {
					return false
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
}