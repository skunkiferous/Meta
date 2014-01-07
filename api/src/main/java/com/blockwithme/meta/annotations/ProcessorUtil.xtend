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

import org.eclipse.xtend.core.macro.declaration.CompilationUnitImpl
import org.eclipse.xtend.lib.macro.declaration.TypeDeclaration
import java.util.List
import org.eclipse.xtend.lib.macro.declaration.MutableTypeDeclaration
import org.eclipse.xtext.common.types.JvmDeclaredType
import org.eclipse.xtext.common.types.JvmType
import org.eclipse.xtext.common.types.impl.JvmGenericTypeImpl
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.EnumerationTypeDeclaration
import java.util.Collections
import org.eclipse.xtend.lib.macro.declaration.ConstructorDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableConstructorDeclaration
import org.eclipse.xtend.lib.macro.declaration.MethodDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableMethodDeclaration
import org.eclipse.xtend.core.macro.declaration.ExpressionImpl
import org.eclipse.xtext.xbase.XBlockExpression
import org.eclipse.xtend.lib.macro.services.Tracability
import org.eclipse.xtend.core.xtend.impl.XtendVariableDeclarationImpl
import java.lang.annotation.Annotation
import java.util.Map
import org.eclipse.xtend.lib.macro.services.TypeLookup
import org.eclipse.xtend.lib.macro.declaration.MutableInterfaceDeclaration

/**
 * Helper methods for active annotation processing.
 *
 * @author monster
 */
class ProcessorUtil {
	private new() {
		// NOP
	}

	/** Debug output? */
	public static val DEBUG = true

	/** Returns the CompilationUnit of those elements */
	static def CompilationUnitImpl getCompilationUnit(
		List<? extends TypeDeclaration> annotatedSourceElements) {
		if (!annotatedSourceElements.empty) {
			val element = annotatedSourceElements.get(0)
			return element.compilationUnit as CompilationUnitImpl
		}
		null
	}

	/** Returns the Xtend types of this CompilationUnit */
	static def Iterable<? extends TypeDeclaration> getXtendTypes(
		CompilationUnitImpl compilationUnit) {
		compilationUnit.xtendFile.xtendTypes
			.map[compilationUnit.toXtendTypeDeclaration(it)]
	}

	/** Returns the mutable types of this CompilationUnit */
	static def Iterable<? extends MutableTypeDeclaration> getMutableTypes(
		CompilationUnitImpl compilationUnit) {
		compilationUnit.xtendFile.eResource.contents.filter(JvmDeclaredType)
			.map[compilationUnit.toTypeDeclaration(it)]
	}

	/** Sometimes, Xtend "forgets" to set the "isInterface" flag on types! */
	private static def fixInterface(JvmType type, boolean isInterface) {
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
	private static def TypeDeclaration lookup(TypeDeclaration td,
		boolean isInterface, String typeName) {
		val compilationUnit = td.compilationUnit as CompilationUnitImpl
		val parentIsJvmType = (td instanceof JvmType)
		if (parentIsJvmType) {
			for (t : compilationUnit.xtendFile.eResource.contents.filter(JvmDeclaredType)) {
				if (t.qualifiedName == typeName) {
					fixInterface(t, isInterface)
					return compilationUnit.toTypeDeclaration(t)
				}
			}
		} else {
			val packageName = compilationUnit.packageName
			for (t : compilationUnit.xtendFile.xtendTypes) {
				if (packageName+'.'+t.name == typeName) {
					// If the type is found here, the interface flag is normally OK
					return compilationUnit.toXtendTypeDeclaration(t)
				}
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
	private static def Iterable<? extends TypeDeclaration> convert(
		TypeDeclaration td, boolean isInterface, Iterable<? extends TypeReference> refs) {
		refs.map[lookup(td, isInterface, it.name)]
	}

	/** Returns the direct parents */
	private static dispatch def Iterable<? extends TypeDeclaration> findDirectParents(TypeDeclaration td) {
		Collections.emptyList
	}

	/** Returns the direct parents */
	private static dispatch def Iterable<? extends TypeDeclaration> findDirectParents(ClassDeclaration td) {
		val result = <TypeDeclaration>newArrayList()
		result.addAll(convert(td, true, td.implementedInterfaces))
		result.addAll(convert(td, false, Collections.singleton(td.extendedClass)))
		result
	}

	/** Returns the direct parents */
	private static dispatch def Iterable<? extends TypeDeclaration> findDirectParents(InterfaceDeclaration td) {
		convert(td, true, td.extendedInterfaces)
	}

	/** Returns the direct parents */
	private static dispatch def Iterable<? extends TypeDeclaration> findDirectParents(EnumerationTypeDeclaration td) {
		// TODO: td.implementedInterfaces is not implemented in EnumerationTypeDeclaration yet!
		Collections.emptyList
	}

	/** Returns the all parents, *including the type itself* */
	static def Iterable<? extends TypeDeclaration> findParents(TypeDeclaration td) {
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
	static def hasDirectAnnotation(TypeDeclaration td, String annotationName) {
		td.annotations.exists[annotationTypeDeclaration.qualifiedName == annotationName]
	}

	/** Does the given type directly bares the desired annotation? */
	static def hasDirectAnnotation(TypeDeclaration td, Class<? extends Annotation> annotation) {
		hasDirectAnnotation(td, annotation.name)
	}

	/** Searches for the *default* constructor. */
	def static ConstructorDeclaration findConstructor(TypeDeclaration clazz) {
		for (c : clazz.declaredConstructors) {
			if (c.parameters.isEmpty) {
				return c
			}
		}
		null
	}

	/** Searches for the *default* constructor. */
	def static MutableConstructorDeclaration findConstructor(MutableClassDeclaration clazz) {
		findConstructor(clazz as TypeDeclaration) as MutableConstructorDeclaration
	}

	/** Searches for the method with the given name and parameters. */
	def static MethodDeclaration findMethod(TypeDeclaration clazz,
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
	def static MutableMethodDeclaration findMethod(MutableClassDeclaration clazz,
		String name, TypeReference ... parameterTypes) {
		findMethod(clazz as TypeDeclaration, name, parameterTypes) as MutableMethodDeclaration
	}

	/** Returns a long trace of all the info of that method. */
	def static String describeMethod(MethodDeclaration m, extension Tracability tracability) {
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

	/** Utility method that finds an interface in the global context, returns null if not found */
	def static findInterface(TypeLookup typeLookup, String name) {
		val found = typeLookup.findTypeGlobally(name)
		if (found instanceof MutableInterfaceDeclaration)
			found as MutableInterfaceDeclaration
		else
			null
	}

	/** Utility method that finds a class in the global context, returns null if not found */
	def static findClass(TypeLookup typeLookup, String name) {
		val found = typeLookup.findTypeGlobally(name)
		if (found instanceof MutableClassDeclaration)
			found as MutableClassDeclaration
		else
			null
	}
}