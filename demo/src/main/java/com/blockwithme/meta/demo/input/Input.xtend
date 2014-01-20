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
package com.blockwithme.meta.demo.input

import com.blockwithme.meta.annotations.Trait
import javax.inject.Provider

//////////////////////////////////////////////////////////
// Framework Types
//////////////////////////////////////////////////////////

// NOT implemented/extended by User
interface Type {
	// ...
}

// NOT implemented/extended by User
interface Property<TYPE> {
	// Would really be in sub-class of Property, so we only have the "right" getXXXDefault()
	def int getIntDefault()
	def TYPE getObjectDefault()
	// ...
}

// Generated automatically
// We need something that both gives the current instance Type as a simple Type
// instance, because that is what generic code (serialization, ...) needs, and
// that thing must be easily injectable, therefore it should be named, but also
// for code that actually knows about the type, you want something where you
// can easily get access to each base-class Type instance, and to each Property
// instance, by name, even the base-class properties. So we generate this
// automatically, and it is both injected in the instance itself, and can be
// injected in anything else interested in that type's meta-info.
// Note that there is both a XXX Type, and a ROXXX Type instance, unfortunately,
// as two different interface should not have a single Type instance.
// @Named("XXXTypeProvider")
//interface XXXTypeProvider Provider<Type> {
//  // This is the actual instance type
//  override Type get()
//	def Type roXxxType()
//	def Type xxxType()
//	// Properties ..
//}

// Implemented automatically
interface ROInstance {
	def Provider<Type> getTypeProvider()
	def Instance copy()
}

// Implemented automatically
interface Instance
extends ROInstance {
	def ROInstance snapshot()
}

// Unseen by use code
abstract class BaseInstance implements ROInstance {
	var Provider<Type> typeProvider
	override Provider<Type> getTypeProvider() {
		typeProvider
	}
	def void setTypeProvider(Provider<Type> typeProvider) {
		this.typeProvider = typeProvider
	}
}

//////////////////////////////////////////////////////////
// User-defined input types (all interfaces)
//////////////////////////////////////////////////////////

@Trait(concrete=false)
interface Aged {
	val age = 0
}

@Trait(concrete=false)
interface Named {
	val name = ""
}

@Trait
interface Person extends Aged, Named {
	val profession = ""
}
