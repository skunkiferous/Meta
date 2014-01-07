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

/**
 * Marker annotation for "beans"
 *
 * @author monster
 */
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.CLASS)
@Inherited
@Active(MagicAnnotationProcessor)
annotation Bean {
}

/**
 * @author monster
 *
 */
class BeanProcessor extends InterfaceProcessor {

	new() {
		super(withAnnotation(Bean))
	}

	/** Register new types, to be generated later. */
	override void register(InterfaceDeclaration td, RegisterGlobalsContext context) {
		warn(td, "register: "+td.qualifiedName)
	}

	/** Generate new types, registered earlier. */
	override void generate(InterfaceDeclaration td, CodeGenerationContext context) {
		warn(td, "generate: "+td.qualifiedName)
	}

	/** Transform types, new or old. */
	override void transform(MutableInterfaceDeclaration mtd, TransformationContext context) {
		warn(mtd, "transform: "+mtd.qualifiedName)
	}

}