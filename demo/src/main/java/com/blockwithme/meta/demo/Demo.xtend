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
package com.blockwithme.meta.demo

import com.blockwithme.meta.annotations.Bean
import com.blockwithme.meta.annotations.ListProperty
import com.blockwithme.meta.annotations.OrderedSetProperty
import com.blockwithme.meta.annotations.SortedSetProperty
import com.blockwithme.meta.annotations.UnorderedSetProperty
import com.blockwithme.meta.annotations.HashSetProperty

/**
 * Hierarchy "root".
 *
 * Basically, within one single file/package, all types have to extend the same "root type".
 * This root type is the "hierarchy root" and gives it's name to the hierarchy.
 */
@Bean
interface Root {
	// NOP
}

/** Example that should we support all type of properties */
@Bean
interface DemoType extends Root {

  /** Boolean property */
  boolean boolProp

  /** Byte property */
  byte byteProp

  /** Short property */
  short shortProp

  /** Char property */
  char charProp

  /** Int property */
  int intProp

  /** Long property */
  long longProp

  /** Float property */
  float floatProp

  /** Double property */
  double doubleProp

  /** Object property */
  String objectProp
}

/** Example of a child type */
@Bean(instance=true)
interface DemoTypeChild extends DemoType {

  /** Internal property */
  int _secret

  /** Child Object property */
  Person childProp

}

/** Aspect of an an Object that has an "age". */
@Bean
interface Aged extends Root {
	/** age of something */
	int age
}

/** Extension for all Aged objects. */
class AgedExt {
	/** Returns true, if the age of the object is 18+ */
	static def boolean adult(Aged aged) {
		aged.age >= 18
	}
}

/** Aspect of an an Object that has a "Name". */
@Bean
interface Named extends Root {
	/** name of something */
	String name
}

/**
 * A Person is an example of Multiple Inheritance.
 * In combines both Named and Aged with it's own data.
 */
@Bean(instance=true,sortKeyes=#["name","age"])
interface Person extends Named, Aged {
	/** profession of someone */
	String profession
}

/** Extension for all Person objects. */
class PersonExt {
	/** Describes a person (by returning their name) */
	static def String desc(Person p) {
		p.name
	}
}

/** Example that has more then 64 properties */
@Bean(instance=true)
interface SixtyFiveProps extends Root {
	boolean prop00
	boolean prop01
	boolean prop02
	boolean prop03
	boolean prop04
	boolean prop05
	boolean prop06
	boolean prop07
	boolean prop08
	boolean prop09
	boolean prop10
	boolean prop11
	boolean prop12
	boolean prop13
	boolean prop14
	boolean prop15
	boolean prop16
	boolean prop17
	boolean prop18
	boolean prop19
	boolean prop20
	boolean prop21
	boolean prop22
	boolean prop23
	boolean prop24
	boolean prop25
	boolean prop26
	boolean prop27
	boolean prop28
	boolean prop29
	boolean prop30
	boolean prop31
	boolean prop32
	boolean prop33
	boolean prop34
	boolean prop35
	boolean prop36
	boolean prop37
	boolean prop38
	boolean prop39
	boolean prop40
	boolean prop41
	boolean prop42
	boolean prop43
	boolean prop44
	boolean prop45
	boolean prop46
	boolean prop47
	boolean prop48
	boolean prop49
	boolean prop50
	boolean prop51
	boolean prop52
	boolean prop53
	boolean prop54
	boolean prop55
	boolean prop56
	boolean prop57
	boolean prop58
	boolean prop59
	boolean prop60
	boolean prop61
	boolean prop62
	boolean prop63
	boolean prop64
}

@Bean(instance=true)
interface CollectionOwner extends Root {
  String[] defaultSet

  @UnorderedSetProperty
  String[] unorderedSet

  @OrderedSetProperty
  String[] orderedSet

  @SortedSetProperty
  String[] sortedSet

  @HashSetProperty
  String[] hashSet

  @ListProperty
  String[] list

  @ListProperty(fixedSize=10)
  String[] fixedSizeList

  @ListProperty(nullAllowed=true)
  String[] nullList
}

///** Example of the Trace annotation */
//@Trace
//class SomeClass {
//	/** The age */
//	int age
//	def hello() { "hello, I'm "+age }
//}
