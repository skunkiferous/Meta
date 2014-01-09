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
package com.blockwithme.meta.demo

import com.blockwithme.meta.annotations.Trait
import com.blockwithme.meta.annotations.Magic

@Magic
@Trait
interface DemoType {

  /** Boolean property */
  val boolProp = false

  /** Byte property */
  val byteProp = 0 as byte

  /** Short property */
  val shortProp = 0 as short

  /** Char property */
  val char charProp = 0 as char

  /** Int property */
  val intProp = 0

  /** Long property */
  val longProp = 0L

  /** Float property */
  val floatProp = 0.0f

  /** Double property */
  val doubleProp = 0.0

  /** Object property */
  val objectProp = ""
}

@Magic
interface DemoTypeChild extends DemoType {

}

@Magic
interface Dummy {

}