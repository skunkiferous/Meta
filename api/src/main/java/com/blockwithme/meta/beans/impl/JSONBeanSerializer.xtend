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

import com.blockwithme.meta.beans._Bean
import com.blockwithme.meta.ObjectProperty
import com.blockwithme.meta.PrimitiveProperty
import com.blockwithme.meta.Property
import java.util.Objects
import com.blockwithme.meta.BooleanProperty

/**
 * A PropertyVisitor that produces a JSON output for beans.
 *
 * @author monster
 */
class JSONBeanSerializer extends AbstractPropertyVisitor {

	/** Property name for the type of an object/beans */
	public static val CLASS = "class"

	/** Property name for the "content" of an object of unknown type */
	public static val CONTENT = "*"

	/** Appendable */
	val Appendable appendable

	/** StringBuilder */
	val buf = new StringBuilder()

	/** Creates the JSONPropertyVisitor */
	new (Appendable appendable) {
		this.appendable = Objects.requireNonNull(appendable, "appendable")
	}

	/** Append Object start */
	protected def void appendObjectStart(Object obj) {
		appendable.append('{"'+CLASS+'":"')
		appendable.append(obj.class.name)
		appendable.append('"')
	}

	/** Append Object end */
	protected def void appendObjectEnd() {
		appendable.append('}')
	}

	/** Called for beans */
	public override void visit(_Bean bean) {
		if (bean !== null) {
			appendObjectStart(bean)
			super.visit(bean)
			appendObjectEnd()
		} else {
			appendable.append('null')
		}
	}

	/** Called for all properties */
	protected override void visit(Property prop) {
		// We always assume there was some other property before this one
		appendable.append(',"').append(prop.simpleName).append('"').append(":")
	}

	/** Visit ObjectProperty with null value */
	protected override void visitNull(ObjectProperty prop) {
		appendable.append('null')
	}

	/** Visit boolean properties */
	protected override void visit(BooleanProperty prop, boolean value) {
		if (value) appendable.append('true') else appendable.append('false')
	}

	/**
	 * All integral primitive properties end up delegating here,
	 * Including boolean.
	 */
	protected override void visitNumber(PrimitiveProperty prop, long value) {
		buf.append(value)
		appendable.append(buf)
		buf.setLength(0)
	}

	/**
	 * All floating-point primitive properties end up delegating here,
	 */
	protected override void visitNumber(PrimitiveProperty prop, double value) {
		val lvalue = value as long
		if (value === lvalue) {
			// This prevents printing .0 ...
			visitNumber(prop, lvalue)
		} else {
			buf.append(value)
			appendable.append(buf)
			buf.setLength(0)
		}
	}

	/**
	 * Visit ObjectProperty with Object value.
	 *
	 * All Object properties end up delegating here.
	 */
	protected override void visitObject(ObjectProperty prop, Object value) {
		// Cannot be null!
		if (value instanceof CharSequence) {
			visitCharSequence(value)
		} else if (value instanceof Class<?>) {
			visitCharSequence(value.name)
		} else if (value instanceof Boolean) {
			if (value.booleanValue) appendable.append('true') else appendable.append('false')
		} else if ((value instanceof Number) && (value.class.package.name == "java.lang")) {
			val number = value as Number
			val lvalue = number.longValue
			val dvalue = number.doubleValue
			if (dvalue === lvalue) {
				visitNumber(null, lvalue)
			} else {
				visitNumber(null, dvalue)
			}
		} else {
			appendObjectStart(value)
			appendable.append(',"'+CONTENT+'":')
			visitCharSequence(value.toString())
			appendObjectEnd()
		}
	}

	/**
	 * Visit ObjectProperty with CharSequence value.
	 *
	 * All Object properties end up delegating here.
	 */
	protected def void visitCharSequence(CharSequence value) {
		appendable.append('"')
		// TODO Probably needs escaping...
		appendable.append(value)
		appendable.append('"')
	}
}