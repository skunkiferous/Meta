/*
 * Copyright (C) 2014 Sebastien Diot.
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
import org.eclipse.xtend.lib.macro.CodeGenerationContext
import org.eclipse.xtend.lib.macro.RegisterGlobalsContext
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.MutableTypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.AnnotationTypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.EnumerationTypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration

interface Filter extends BooleanFuncObjectObject<ProcessorUtil,TypeDeclaration> {
	// NOP
}

/**
 * Filter for Annotations, that take the (optional) inherited nature of annotations into account.
 */
@Data
package class AnnotatedFilter implements Filter {
	String name
	boolean inherited

	private static def check(extension ProcessorUtil processorUtil, TypeDeclaration orig, TypeDeclaration td, String name) {
		hasDirectAnnotation(td, name)
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
}

/**
 * Combines Filters using the AND logic operator
 */
@Data
package class AndFilter implements Filter {
	Filter[] others

	override apply(extension ProcessorUtil processorUtil, TypeDeclaration td) {
		for (f : others) {
			if (!f.apply(processorUtil, td)) {
				return false
			}
		}
		true
	}
}

/**
 * Combines Filters using the OR logic operator
 */
@Data
package class OrFilter implements Filter {
	Filter[] others

	override apply(extension ProcessorUtil processorUtil, TypeDeclaration td) {
		for (f : others) {
			if (f.apply(processorUtil, td)) {
				return true
			}
		}
		false
	}
}

/**
 * Negates the result of another Filter
 */
@Data
package class NotFilter implements Filter {
	Filter other

	override apply(extension ProcessorUtil processorUtil, TypeDeclaration td) {
		!other.apply(processorUtil, td)
	}
}

/**
 * Accepts, if the validated type has the desired type as parent
 * (either base class or implemented interface)
 */
@Data
package class ParentFilter implements Filter {
	String parent

	override apply(extension ProcessorUtil processorUtil, TypeDeclaration td) {
		for (p : processorUtil.findParents(td)) {
			if (p.qualifiedName == parent) {
				return true
			}
		}
		false
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
	val Filter filter
	protected var extension ProcessorUtil processorUtil

	protected static def Filter withAnnotation(String name, boolean inherited) {
		new AnnotatedFilter(name, inherited)
	}

	protected static def Filter withAnnotation(Class<? extends Annotation> type) {
		withAnnotation(type.name, type.annotations.exists[annotationType === Inherited])
	}

	protected static def Filter and(Filter ... filters) {
		new AndFilter(filters)
	}

	protected static def Filter or(Filter ... filters) {
		new OrFilter(filters)
	}

	protected static def Filter not(Filter filter) {
		new NotFilter(filter)
	}

	protected static def Filter hasParent(String qualifiedName) {
		new ParentFilter(qualifiedName)
	}

	protected static def Filter hasParent(Class<?> parent) {
		new ParentFilter(parent.name)
	}

	protected static val Filter isAnnotation = [pu,td|td instanceof AnnotationTypeDeclaration]

	protected static val Filter isClass = [pu,td|td instanceof ClassDeclaration]

	protected static val Filter isEnum = [pu,td|td instanceof EnumerationTypeDeclaration]

	protected static val Filter isInterface = [pu,td|td instanceof InterfaceDeclaration]

	/**
	 * Creates a processor with an *optional* filter.
	 * If specified, the filter must return *true* to accept a type.
	 */
	protected new(Filter filter) {
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
			init()
		} else {
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

	/** Transform types, new or old. */
	def void transform(M mtd, TransformationContext context) {
		// NOP
	}

	/** Generate new types, registered earlier. */
	def void generate(T td, CodeGenerationContext context) {
		// NOP
	}
}