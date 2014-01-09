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

import java.lang.annotation.ElementType
import java.lang.annotation.Inherited
import java.lang.annotation.Retention
import java.lang.annotation.RetentionPolicy
import java.lang.annotation.Target
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.CodeGenerationContext
import org.eclipse.xtend.lib.macro.RegisterGlobalsContext
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableInterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import org.eclipse.xtend.core.macro.declaration.CompilationUnitImpl
import org.eclipse.xtend.lib.macro.declaration.Type
import java.util.Set
import java.io.Serializable
import com.blockwithme.fn.util.Functor
import java.util.List
import com.blockwithme.traits.util.IndentationAwareStringBuilder
import java.util.Arrays
import java.util.Objects
import org.eclipse.xtend.lib.macro.services.TypeLookup
import org.eclipse.xtend.lib.macro.declaration.TypeDeclaration

/**
 * Annotation for "traits"
 *
 * @author monster
 */
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.CLASS)
@Inherited
@Active(MagicAnnotationProcessor)
annotation Trait {
	/** If the immutable it true all fields are final,
	 * and setter methods will return a new instance*/
	boolean immutable = false
}

/** A Temp class used to get a <code>count</code> output from a lambda function. */
package class Counter {
	package int count
}

/** A Temp class used to get a <code>boolean</code> output from a lambda function. */
package class BooleanFlag {
	package boolean value
}

/** Temp data structure used for Template generation. */
package class TemplateField {

	package String fieldName

	package String accessor

	package String mutator

	package String templateFieldName

	package TypeReference fieldType

	package MutableInterfaceDeclaration interf

}

/**
 * @author monster
 *
 */
class TraitProcessor extends InterfaceProcessor {

	extension TransformationContext context

	/** The following type references are resolved at the setup time */
	var Type traitAnnotation
	var TypeReference builderType

	private def boolean isValidTraitOrMarker(TypeDeclaration _interface) {
		if ((_interface.findAnnotation(traitAnnotation) != null) || isMarker(_interface)) {
			for (parent : findParents(_interface)) {
				if (!isValidTraitOrMarker(parent)) {
					return false
				}
			}
			return true
		}
		false
	}

	/** A Validator method to check if interface okay to be a trait
	 * i.e. it should be annotated with @Trait and
	 * should not have any methods of its own.
	 *
	 * TODO This method has some problems doesn't work atm. */
	@SuppressWarnings("unused")
	private def boolean isValidTrait(TypeDeclaration _interface) {
		if (_interface.findAnnotation(traitAnnotation) != null) {
			for (parent : findParents(_interface)) {
				if (!isValidTraitOrMarker(parent)) {
					return false
				}
			}
			return true
		}
		false
	}

	new() {
		super(withAnnotation(Trait))
	}

	/** Called before processing a file. */
	override void init() {
		traitAnnotation = processorUtil.findTypeGlobally(Trait)
		builderType = typeReferenceProvider.newTypeReference(IndentationAwareStringBuilder)
	}

	/** Called after processing a file. */
	override void deinit() {
		traitAnnotation = null
		builderType = null
	}

	/** Register new types, to be generated later. */
	override void register(InterfaceDeclaration td, RegisterGlobalsContext context) {
		context.registerClass(td.qualifiedName + "Trait")
//		context.registerClass(td.qualifiedName + "Template")
		warn(td, "register: "+td.qualifiedName)
	}

	/** Generate new types, registered earlier. */
	override void generate(InterfaceDeclaration td, CodeGenerationContext context) {
		warn(td, "generate: "+td.qualifiedName)
	}

	/** Transform types, new or old. */
	override void transform(MutableInterfaceDeclaration mtd, TransformationContext context) {
		this.context = context
		warn(mtd, "transform: "+mtd.qualifiedName)
	}

}