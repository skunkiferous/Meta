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

import com.blockwithme.fn1.BooleanFuncObject
import java.io.PrintWriter
import java.io.StringWriter
import java.lang.annotation.Annotation
import java.lang.annotation.Inherited
import java.util.Map
import org.eclipse.xtend.core.macro.declaration.CompilationUnitImpl
import org.eclipse.xtend.lib.macro.CodeGenerationContext
import org.eclipse.xtend.lib.macro.RegisterGlobalsContext
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.Element
import org.eclipse.xtend.lib.macro.declaration.MutableTypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeDeclaration
import org.eclipse.xtend.lib.macro.services.ProblemSupport

/**
 * Filter for Annotations, that take the (optional) inherited nature of annotations into account.
 */
package final class AnnotationFilter implements BooleanFuncObject<TypeDeclaration> {
	val String name
	val boolean inherited

	new(String name, boolean inherited) {
		this.name = name
		this.inherited = inherited
	}

	private static def check(TypeDeclaration orig, TypeDeclaration td, String name) {
		val result = ProcessorUtil.hasDirectAnnotation(td, name)
		if (ProcessorUtil.DEBUG) {
			val compilationUnit = td.compilationUnit as CompilationUnitImpl
			val problemSupport = compilationUnit.problemSupport
			val msg = "check("+orig.class.simpleName+"("+orig.simpleName+"), "+td.class.simpleName+"("+td.simpleName+"), "+name+"): "+result
			problemSupport.addWarning(td, msg)
		}
		result
	}

	override apply(TypeDeclaration td) {
		if (inherited) {
			for (parent : ProcessorUtil.findParents(td)) {
				if (check(td, parent, name)) {
					return true
				}
			}
			return false
		}
		check(td, td, name)
	}

	override final toString() {
		"AnnotationFilter(name="+name+",inherited="+inherited+")"
	}
}

/**
 * Base class for our own Processors (annotation-bound or not).
 *
 * The actual processor instances must have a public no-argument constructor.
 *
 * @author monster
 */
class Processor<T extends TypeDeclaration, M extends MutableTypeDeclaration> {
	val BooleanFuncObject<TypeDeclaration> filter
	var ProblemSupport problemSupport
	var Map<String,Object> cache
	var String file
	var TypeDeclaration type

	protected static def BooleanFuncObject<TypeDeclaration> withAnnotation(String name, boolean inherited) {
		new AnnotationFilter(name, inherited)
	}

	protected static def BooleanFuncObject<TypeDeclaration> withAnnotation(Class<? extends Annotation> type) {
		withAnnotation(type.name, type.annotations.exists[annotationType === Inherited])
	}

	/**
	 * Creates a processor with an *optional* filter.
	 * If specified, the filter must return *true* to accept a type.
	 */
	protected new(BooleanFuncObject<TypeDeclaration> filter) {
		this.filter = filter
	}

	/** Returns the configuration as a string */
	protected def config() {
		"filter="+filter
	}

	override final toString() {
		class.name+"("+config+")"
	}

	/** Sets the fields */
	package final def void setup(ProblemSupport problemSupport, Map<String,Object> cache,
		String file, TypeDeclaration type) {
		this.problemSupport = problemSupport
		this.cache = cache
		this.file = file
		this.type = type
	}

	/** Clears the fields */
	package final def void clear() {
		setup(null, null, null, null)
	}

	/**
	 * Computes a default prefix for get/put.
	 * Defaults to filename/classname/
	 */
	private def String prefix() {
		file+"/"+type.qualifiedName+"/"
	}

	/**
	 * Records an error for the given element
	 *
	 * @param element the element to which associate the message
	 * @param message the message
	 */
	protected final def void error(Element element, String message) {
		problemSupport.addError(element, message)
	}

	/**
	 * Records a warning for the given element
	 *
	 * @param element the element to which associate the message
	 * @param message the message
	 */
	protected final def void warn(Element element, String message) {
		problemSupport.addWarning(element, message)
	}

	/**
	 * Records a warning for the currently processed type
	 *
	 * @param message the message
	 */
	protected final def void warn(String message) {
		problemSupport.addWarning(type, message)
	}

	/**
	 * Records an error for the currently processed type
	 *
	 * @param message the message
	 */
	protected final def void error(String message) {
		problemSupport.addError(type, message)
	}

	/** Reads from the cache, using a specified prefix. */
	protected final def Object get(String prefix, String key) {
		cache.get(prefix+key)
	}

	/** Writes to the cache, using a specified prefix. */
	protected final def Object put(String prefix, String key, Object newValue) {
		if (newValue === null) {
			cache.remove(prefix+key)
		} else {
			cache.put(prefix+key, newValue)
		}
	}

	/** Reads from the cache, using the default prefix. */
	protected final def Object get(String key) {
		cache.get(prefix+key)
	}

	/** Writes to the cache, using the default prefix. */
	protected final def Object put(String key, Object newValue) {
		if (newValue === null) {
			cache.remove(prefix+key)
		} else {
			cache.put(prefix+key, newValue)
		}
	}

	/** Returns true, if this type should be processed. */
	def boolean accept(TypeDeclaration td) {
		(filter === null) || filter.apply(td)
	}

	/** Register new types, to be generated later. */
	def void register(T td, RegisterGlobalsContext context) {
		// NOP
	}

	/** Generate new types, registered earlier. */
	def void generate(T td, CodeGenerationContext context) {
		// NOP
	}

	/** Transform types, new or old. */
	def void transform(M mtd, TransformationContext context) {
		// NOP
	}
}