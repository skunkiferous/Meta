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
package com.blockwithme.meta.beans.impl

import com.blockwithme.meta.Property
import com.blockwithme.meta.PropertyVisitor
import com.blockwithme.meta.BooleanProperty
import com.blockwithme.meta.ByteProperty
import com.blockwithme.meta.CharacterProperty
import com.blockwithme.meta.ShortProperty
import com.blockwithme.meta.IntegerProperty
import com.blockwithme.meta.FloatProperty
import com.blockwithme.meta.DoubleProperty
import com.blockwithme.meta.LongProperty
import com.blockwithme.meta.ObjectProperty
import com.blockwithme.meta.beans._BeanBase
import java.util.Objects
import java.util.IdentityHashMap

/**
 * A PropertyVisitor that produces a JSON output for beans.
 *
 * @author monster
 */
class JSONBeanSerializer implements PropertyVisitor {

	/** Map the objects already appended to their path */
	val beanToPath = new IdentityHashMap<_BeanBase,String>()

	/** Appendable */
	val Appendable appendable

	/** The top of the bean stack */
	var _BeanBase bean

	/** The path so far */
	var String path = "/"

	/** Creates the JSONPropertyVisitor */
	new (Appendable appendable, _BeanBase bean) {
		this.appendable = Objects.requireNonNull(appendable, "appendable")
		this.bean = Objects.requireNonNull(bean, "bean")
	}

	/** Visit all the properties of the Object */
	def void visit() {
		beanToPath.put(bean,path)
		appendable.append('{class:"')
		appendable.append(bean.class.name)
		appendable.append('"')
		for (p : bean.type.inheritedProperties) {
			p.accept(this)
		}
		appendable.append('}')
	}

	/** Appends the property name */
	private def appendName(Property<?, ?> prop) {
		// We always assume there was some other property before this one
		appendable.append(',"').append(prop.simpleName).append('"').append(":")
	}

	/** Appends a number */
	private def appendNumber(double number) {
		appendable.append(String.valueOf(number))
	}

	/** Appends a value as String */
	private def appendString(Object value) {
		if (value === null) {
			appendable.append('null')
		} else {
			appendable.append('"')
			// TODO Probably needs escaping...
			appendable.append(value.toString())
			appendable.append('"')
		}
	}

	override visit(BooleanProperty prop) {
		appendName(prop)
		appendable.append(if (prop.getBoolean(bean)) "true" else "false")
	}

	override visit(ByteProperty prop) {
		appendName(prop)
		appendNumber(prop.getByte(bean))
	}

	override visit(CharacterProperty prop) {
		appendName(prop)
		// char to String conversion is intentional
		appendString(prop.getChar(bean))
	}

	override visit(ShortProperty prop) {
		appendName(prop)
		appendNumber(prop.getShort(bean))
	}

	override visit(IntegerProperty prop) {
		appendName(prop)
		appendNumber(prop.getInt(bean))
	}

	override visit(FloatProperty prop) {
		appendName(prop)
		appendNumber(prop.getFloat(bean))
	}

	override visit(DoubleProperty prop) {
		appendName(prop)
		appendNumber(prop.getDouble(bean))
	}

	override visit(LongProperty prop) {
		appendName(prop)
		appendable.append(String.valueOf(prop.getLong(bean)))
	}

	override visit(ObjectProperty prop) {
		appendName(prop)
		val obj = prop.getObject(bean)
		if (obj === null) {
			appendable.append("null")
		} else if (obj instanceof _BeanBase) {
			val done = beanToPath.get(obj)
			if (done === null) {
				val prev = bean
				val prevPath = path
				bean = obj as _BeanBase
				if (path != "/") {
					path = path + "/"
				}
				path = path + prop.simpleName
				visit()
				bean = prev
				path = prevPath
			} else {
				appendable.append('{path:"')
				appendable.append(done)
				appendable.append('"}')
			}
		} else {
			appendString(obj)
		}
	}
}