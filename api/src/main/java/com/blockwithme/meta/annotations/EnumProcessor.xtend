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
import org.eclipse.xtend.lib.macro.declaration.EnumerationTypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableEnumerationTypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeDeclaration

/**
 * A Processor that only works on Enumeration types
 *
 * @author monster
 */
class EnumProcessor extends Processor<EnumerationTypeDeclaration, MutableEnumerationTypeDeclaration> {

	/**
	 * Creates a processor with an *optional* filter.
	 * If specified, the filter must return *true* to accept a type.
	 */
	protected new(BooleanFuncObjectObject<ProcessorUtil,TypeDeclaration> filter) {
		super(filter)
	}

	/** Returns true, if this type is an Enumeration that should be processed. */
	override boolean accept(TypeDeclaration td) {
		(td instanceof EnumerationTypeDeclaration) && super.accept(td)
	}
}