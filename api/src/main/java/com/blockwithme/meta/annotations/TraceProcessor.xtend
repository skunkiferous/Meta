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

import org.eclipse.xtend.lib.macro.CodeGenerationContext
import org.eclipse.xtend.lib.macro.RegisterGlobalsContext
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.MutableTypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeDeclaration

import static extension com.blockwithme.meta.annotations.ProcessorUtil.*

/**
 * Gives traces about all types "seen".
 *
 * @author monster
 */
class TraceProcessor extends TypeProcessor {

	new() {
		super(null)
	}

	/** Register new types, to be generated later. */
	override void register(TypeDeclaration td, RegisterGlobalsContext context) {
		warn("register: "+td.qualifiedName)
	}

	/** Generate new types, registered earlier. */
	override void generate(TypeDeclaration td, CodeGenerationContext context) {
		warn("generate: "+td.qualifiedName)
	}

	/** Transform types, new or old. */
	override void transform(MutableTypeDeclaration mtd, TransformationContext context) {
		warn("transform: "+mtd.qualifiedName)
		for (m : mtd.declaredMethods) {
			warn("transform: "+mtd.qualifiedName+"."+m.simpleName+"\n "+m.describeMethod(context))
		}
	}
}