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
package com.blockwithme.meta.demo.output

import com.blockwithme.meta.demo.input.Type
import com.blockwithme.meta.demo.input.Property
import com.blockwithme.meta.demo.input.Entity

//////////////////////////////////////////////////////////
// Transformed and generated types
//////////////////////////////////////////////////////////

interface AgedRO<I_SELF extends AgedRO/*<I_SELF, M_SELF>*/,
M_SELF extends Aged/*<I_SELF, M_SELF>*/>
extends Entity {
	val ageDefault = 0
	def int getAge()
	def M_SELF copy()
}

interface Aged<I_SELF extends AgedRO/*<I_SELF, M_SELF>*/,
M_SELF extends Aged/*<I_SELF, M_SELF>*/>
extends AgedRO<I_SELF, M_SELF> {
	def M_SELF setAge(int age)
	def I_SELF snapshot()
	def void copyFrom(I_SELF other)
}

package class AgedROImpl<I_SELF extends AgedRO/*<I_SELF, M_SELF>*/,
M_SELF extends Aged/*<I_SELF, M_SELF>*/>
implements AgedRO<I_SELF, M_SELF> {
	protected var int age = ageDefault

	override int getAge() {
		age
	}

	override copy() {
		val result = new AgedImpl()
		result.copyFrom(this)
		result as M_SELF
	}

	// Not visible when using interface AgedRO
	def M_SELF setAge(int age) {
		this.age = age
		this as M_SELF
	}

	// Not visible when using interface AgedRO
	def snapshot() {
		val result = new AgedROImpl()
		result.copyFrom(this)
		result as I_SELF
	}

	// Not visible when using interface AgedRO
	def void copyFrom(I_SELF other) {
		if (other === null) {
			this.age = AgedRO.ageDefault
		} else {
			this.age = other.age
		}
	}

	package def void initialize(int age) {
		this.age = age
	}

	override metaType() {
		AgedExtension.AGED_CLASS
	}

	// toString
	// hashCode
	// equals
	// ...
}

package class AgedImpl<I_SELF extends AgedRO/*<I_SELF, M_SELF>*/,
M_SELF extends Aged/*<I_SELF, M_SELF>*/>
extends AgedROImpl<I_SELF, M_SELF>
implements Aged<I_SELF, M_SELF> {
}

class AgedExtension {
	public static var Type AGED_CLASS // Injected? Package Static Property?
	public static var Property AGED_AGE // Injected? Package Static Property?

	static def AgedRO newAgedRO(int age) {
		val result = new AgedROImpl
		result.initialize(age)
		result
	}

	static def Aged newAged(int age) {
		val result = new AgedImpl
		result.initialize(age)
		result
	}

	public static val adult = [AgedRO it|it.age >= 18]
	static def adult(AgedRO aged) {
		adult.apply(aged)
	}
}




interface NamedRO<I_SELF extends NamedRO/*<I_SELF, M_SELF>*/,
M_SELF extends Named/*<I_SELF, M_SELF>*/>
extends Entity {
	val nameDefault = ""
	def String getName()
	def M_SELF copy()
}

interface Named<I_SELF extends NamedRO/*<I_SELF, M_SELF>*/,
M_SELF extends Named/*<I_SELF, M_SELF>*/>
extends NamedRO<I_SELF, M_SELF> {
	def M_SELF setName(String name)
	def I_SELF snapshot()
	def void copyFrom(I_SELF other)
}

package class NamedROImpl<I_SELF extends NamedRO/*<I_SELF, M_SELF>*/,
M_SELF extends Named/*<I_SELF, M_SELF>*/>
implements NamedRO<I_SELF, M_SELF> {
	protected var String name = nameDefault

	override String getName() {
		name
	}

	override copy() {
		val result = new NamedImpl()
		result.copyFrom(this)
		result as M_SELF
	}

	// Not visible when using interface NamedRO
	def M_SELF setName(String name) {
		this.name = name
		this as M_SELF
	}

	// Not visible when using interface NamedRO
	def snapshot() {
		val result = new NamedROImpl()
		result.copyFrom(this)
		result as I_SELF
	}

	// Not visible when using interface NamedRO
	def void copyFrom(I_SELF other) {
		if (other === null) {
			this.name = NamedRO.nameDefault
		} else {
			this.name = other.name
		}
	}

	package def void initialize(String name) {
		this.name = name
	}

	override metaType() {
		NamedExtension.NAMED_CLASS
	}

	// toString
	// hashCode
	// equals
	// ...
}

package class NamedImpl<I_SELF extends NamedRO/*<I_SELF, M_SELF>*/,
M_SELF extends Named/*<I_SELF, M_SELF>*/>
extends NamedROImpl<I_SELF, M_SELF>
implements Named<I_SELF, M_SELF> {
}

class NamedExtension {
	public static var Type NAMED_CLASS // Injected? Package Static Property?
	public static var Property NAMED_AGE // Injected? Package Static Property?

	static def NamedRO newNamedRO(String name) {
		val result = new NamedROImpl
		result.initialize(name)
		result
	}

	static def Named newNamed(String name) {
		val result = new NamedImpl
		result.initialize(name)
		result
	}

	// ..
}



interface PersonRO<I_SELF extends PersonRO/*<I_SELF, M_SELF>*/,
M_SELF extends Person/*<I_SELF, M_SELF>*/>
extends AgedRO<I_SELF, M_SELF>, NamedRO<I_SELF, M_SELF> {
	val professionDefault = ""
	def String getProfession()
}

interface Person<I_SELF extends PersonRO/*<I_SELF, M_SELF>*/,
M_SELF extends Person/*<I_SELF, M_SELF>*/>
extends PersonRO<I_SELF, M_SELF>, Aged<I_SELF, M_SELF>, Named<I_SELF, M_SELF> {
	def M_SELF setProfession(String profession)
}

package class PersonROImpl<I_SELF extends PersonRO/*<I_SELF, M_SELF>*/,
M_SELF extends Person/*<I_SELF, M_SELF>*/>
extends AgedROImpl<I_SELF, M_SELF>
implements PersonRO<I_SELF, M_SELF>
{
	protected var String profession = professionDefault
	protected var String name = nameDefault

	override String getName() {
		name
	}

	override String getProfession() {
		profession
	}

	override copy() {
		val result = new PersonImpl()
		result.copyFrom(this)
		result as M_SELF
	}

	// Not visible when using interface PersonRO
	def M_SELF setProfession(String profession) {
		this.profession = profession
		this as M_SELF
	}

	// Not visible when using interface PersonRO
	def setName(String name) {
		this.name = name
		this as M_SELF
	}

	// Not visible when using interface PersonRO
	override snapshot() {
		val result = new PersonROImpl()
		result.copyFrom(this)
		result as I_SELF
	}

	// Not visible when using interface PersonRO
	override void copyFrom(I_SELF other) {
		super.copyFrom(other)
		if (other === null) {
			this.name = NamedRO.nameDefault
			this.profession = PersonRO.professionDefault
		} else {
			this.name = other.name
			this.profession = other.profession
		}
	}

	override metaType() {
		PersonExtension.PERSON_CLASS
	}

	package def void initialize(int age, String name, String profession) {
		this.age = age
		this.name = name
		this.profession = profession
	}

	// toString
	// hashCode
	// equals
	// ...
}

package class PersonImpl<I_SELF extends PersonRO/*<I_SELF, M_SELF>*/,
M_SELF extends Person/*<I_SELF, M_SELF>*/>
extends PersonROImpl<I_SELF, M_SELF>
implements Person<I_SELF, M_SELF> {
}

class PersonExtension {
	public static var Type PERSON_CLASS // Injected? Package Static Property?
	public static var Property PERSON_AGE // Injected? Package Static Property?

	static def PersonRO newPersonRO(int age, String name, String profession) {
		val result = new PersonROImpl
		result.initialize(age, name, profession)
		result
	}

	static def Person newPerson(int age, String name, String profession) {
		val result = new PersonImpl
		result.initialize(age, name, profession)
		result
	}
	// ..
}


class AgeTest {
	static def void main(String[] args) {
		val o = AgedExtension.newAgedRO(42)
		System.out.println(o)
		System.out.println(o instanceof Aged)
		val p = o.copy
		System.out.println(p)
	}
}