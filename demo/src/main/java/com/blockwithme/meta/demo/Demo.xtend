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
import com.blockwithme.meta.annotations.Trace

/** Example that should we support all type of properties */
@Bean
interface DemoType {

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
@Bean
interface DemoTypeChild extends DemoType {

  /** Internal property */
  int _secret

  /** Child Object property */
  String childProp

}

/** Example of the Trace annotation */
@Trace
class SomeClass {
	/** The age */
	int age
	def hello() { "hello, I'm "+age }
}

/** Aspect of an an Object that has an "age". */
@Bean
interface Aged {
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
interface Named {
	/** name of something */
	String name
}

/**
 * A Person is an example of Multiple Inheritance.
 * In combines both Named and Aged with it's own data.
 */
@Bean
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
