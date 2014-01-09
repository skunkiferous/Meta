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

import com.blockwithme.fn2.BooleanFuncObjectObject
import java.lang.annotation.Annotation
import java.lang.annotation.Inherited
import org.eclipse.xtend.core.macro.declaration.CompilationUnitImpl
import org.eclipse.xtend.lib.macro.CodeGenerationContext
import org.eclipse.xtend.lib.macro.RegisterGlobalsContext
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.MutableTypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeDeclaration
import org.eclipse.xtend.lib.macro.services.TypeReferenceProvider

/**
 * Filter for Annotations, that take the (optional) inherited nature of annotations into account.
 */
package final class AnnotationFilter implements BooleanFuncObjectObject<ProcessorUtil,TypeDeclaration> {
	val String name
	val boolean inherited

	new(String name, boolean inherited) {
		this.name = name
		this.inherited = inherited
	}

	private static def check(extension ProcessorUtil processorUtil, TypeDeclaration orig, TypeDeclaration td, String name) {
		val result = hasDirectAnnotation(td, name)
		if (ProcessorUtil.DEBUG) {
			val compilationUnit = td.compilationUnit as CompilationUnitImpl
			val problemSupport = compilationUnit.problemSupport
			val msg = "check("+orig.class.simpleName+"("+orig.simpleName+"), "+td.class.simpleName+"("+td.simpleName+"), "+name+"): "+result
			problemSupport.addWarning(td, ProcessorUtil.time+msg)
		}
		result
	}

	override apply(extension ProcessorUtil processorUtil, TypeDeclaration td) {
		if (inherited) {
			for (parent : findParents(td)) {
				if (check(processorUtil, td, parent, name)) {
					return true
				}
			}
			return false
		}
		check(processorUtil, td, td, name)
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
	val BooleanFuncObjectObject<ProcessorUtil,TypeDeclaration> filter
	protected var extension ProcessorUtil processorUtil
	protected var extension TypeReferenceProvider typeReferenceProvider

	protected static def BooleanFuncObjectObject<ProcessorUtil,TypeDeclaration> withAnnotation(String name, boolean inherited) {
		new AnnotationFilter(name, inherited)
	}

	protected static def BooleanFuncObjectObject<ProcessorUtil,TypeDeclaration> withAnnotation(Class<? extends Annotation> type) {
		withAnnotation(type.name, type.annotations.exists[annotationType === Inherited])
	}

	/**
	 * Creates a processor with an *optional* filter.
	 * If specified, the filter must return *true* to accept a type.
	 */
	protected new(BooleanFuncObjectObject<ProcessorUtil,TypeDeclaration> filter) {
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
	package final def void setProcessorUtil(ProcessorUtil processorUtil) {
		this.processorUtil = processorUtil
		if (processorUtil != null) {
			typeReferenceProvider = processorUtil.compilationUnit.typeReferenceProvider
			init()
		} else {
			typeReferenceProvider = null
			deinit()
		}
	}

	/** Called before processing a file. */
	def void init() {
		// NOP
	}

	/** Called after processing a file. */
	def void deinit() {
		// NOP
	}

	/** Returns true, if this type should be processed. */
	def boolean accept(TypeDeclaration td) {
		(filter === null) || filter.apply(processorUtil,td)
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