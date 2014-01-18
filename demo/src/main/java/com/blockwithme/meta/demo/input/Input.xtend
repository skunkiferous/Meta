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
package com.blockwithme.meta.demo.input

import com.blockwithme.meta.annotations.Trait

//////////////////////////////////////////////////////////
// Framework Types
//////////////////////////////////////////////////////////

// NOT implemented/extended by User
interface Type {
	// ...
}

// NOT implemented/extended by User
interface Property {
	// ...
}

// Implemented automatically
interface Entity {
	def Type metaType()
}

//////////////////////////////////////////////////////////
// User-defined input types (all interfaces)
//////////////////////////////////////////////////////////

@Trait
interface Aged /*extends Entity*/ {
	val age = 0
	// Define derived properties and helpers as lambdas:
//	val adult = [Aged it|it.age >= 18]
}

@Trait
interface Named /*extends Entity*/ {
	val name = ""
}

@Trait
interface Person extends Aged, Named {
	val profession = ""
}
