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
package com.blockwithme.meta.demo.output

import com.blockwithme.meta.demo.input.Type
import com.blockwithme.meta.demo.input.Property
import com.blockwithme.meta.demo.input.Instance
import com.blockwithme.meta.demo.input.ROInstance
import com.blockwithme.meta.demo.input.BaseInstance

//////////////////////////////////////////////////////////
// Transformed and visible generated types
//////////////////////////////////////////////////////////

interface AgedTypeProvider {
	def Type agedType()
	def Property<Integer> getAge()
}

interface ROAged extends ROInstance {
	def int getAge()
}

interface Aged extends ROAged, Instance {
	def Aged setAge(int age)
}



interface NamedTypeProvider {
	def Type namedType()
	def Property<String> getName()
}

interface RONamed extends ROInstance {
	def String getName()
}

interface Named extends RONamed, Instance {
	def Named setName(String name)
}



interface PersonTypeProvider extends AgedTypeProvider, NamedTypeProvider {
	def Type personType()
	def Property<String> getProfession()
}

interface ROPerson extends ROAged, RONamed {
	def String getProfession()
}

interface Person extends ROPerson, Aged, Named {
	override Person setAge(int age)
	override Person setName(String name)
	def Person setProfession(String profession)
}

//////////////////////////////////////////////////////////
// Invisible generated types
//////////////////////////////////////////////////////////

package abstract class ROAgedImpl extends BaseInstance implements ROAged {
	protected var int age

	override int getAge() {
		age
	}

	// Not visible when using interface ROAged
	def Aged setAge(int age) {
		this.age = age
		this as Aged
	}

	protected def void copyFrom2(ROAged other) {
		if (other === null) {
			this.age = 0
		} else {
			this.age = other.age
		}
	}

	package def void initialize(int age) {
		this.age = age
	}

	// toString
	// hashCode
	// equals
	// ...
}

package abstract class AgedImpl extends ROAgedImpl implements Aged {

}




package abstract class RONamedImpl extends BaseInstance implements RONamed {
	protected var String name

	override String getName() {
		name
	}

	// Not visible when using interface RONamed
	def Named setName(String name) {
		this.name = name
		this as Named
	}

	protected def void copyFrom2(RONamed other) {
		if (other === null) {
			this.name = null
		} else {
			this.name = other.name
		}
	}

	package def void initialize(String name) {
		this.name = name
	}

	// toString
	// hashCode
	// equals
	// ...
}

package abstract class NamedImpl extends RONamedImpl implements Named {
}



package class ROPersonImpl extends ROAgedImpl implements ROPerson
{
	protected var String profession
	protected var String name

	override String getName() {
		name
	}

	override String getProfession() {
		profession
	}

	override copy() {
		val result = new PersonImpl()
		result.copyFrom2(this)
		result as Person
	}

	// Not visible when using interface ROPerson
	def Person setProfession(String profession) {
		this.profession = profession
		this as Person
	}

	// Not visible when using interface ROPerson
	def setName(String name) {
		this.name = name
		this as Person
	}

	override Person setAge(int age) {
		super.setAge(age) as Person
	}

	// Not visible when using interface ROPerson
	def snapshot() {
		val result = new ROPersonImpl()
		result.copyFrom2(this)
		result as ROPerson
	}

	// Not visible when using interface ROPerson
	protected def void copyFrom2(ROPerson other) {
		super.copyFrom2(other)
		if (other === null) {
			this.name = null
			this.profession = null
		} else {
			this.name = other.name
			this.profession = other.profession
		}
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

package class PersonImpl extends ROPersonImpl implements Person {
}

class PersonExtension {
	public static var Type PERSON_CLASS // Injected? Package Static Property?
	public static var Property PERSON_AGE // Injected? Package Static Property?

	static def ROPerson newROPerson(int age, String name, String profession) {
		val result = new ROPersonImpl
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
		val o = PersonExtension.newROPerson(42, "john", "dentist")
		System.out.println(o)
		System.out.println(o instanceof ROPerson)
		val p = o.copy
		System.out.println(p)
	}
}