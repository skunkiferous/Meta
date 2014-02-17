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

import com.blockwithme.meta.BooleanProperty
import com.blockwithme.meta.ByteProperty
import com.blockwithme.meta.CharacterProperty
import com.blockwithme.meta.DoubleProperty
import com.blockwithme.meta.FloatProperty
import com.blockwithme.meta.IntegerProperty
import com.blockwithme.meta.LongProperty
import com.blockwithme.meta.ObjectProperty
import com.blockwithme.meta.PrimitiveProperty
import com.blockwithme.meta.Property
import com.blockwithme.meta.PropertyVisitor
import com.blockwithme.meta.ShortProperty
import com.blockwithme.meta.beans._Bean
import com.blockwithme.meta.beans._Entity

/**
 * A base class for PropertyVisitors.
 *
 * @author monster
 */
abstract class AbstractPropertyVisitor implements PropertyVisitor {
	/** The top of the bean stack */
	private _Bean bean

	final override void visit(BooleanProperty prop) {
		visit(prop)
		visit(prop, prop.getBoolean(bean))
	}

	final override void visit(ByteProperty prop) {
		visit(prop)
		visit(prop, prop.getByte(bean))
	}

	final override void visit(CharacterProperty prop) {
		visit(prop)
		visit(prop, prop.getChar(bean))
	}

	final override void visit(ShortProperty prop) {
		visit(prop)
		visit(prop, prop.getShort(bean))
	}

	final override void visit(IntegerProperty prop) {
		visit(prop)
		visit(prop, prop.getInt(bean))
	}

	final override void visit(LongProperty prop) {
		visit(prop)
		visit(prop, prop.getLong(bean))
	}

	final override void visit(FloatProperty prop) {
		visit(prop)
		visit(prop, prop.getFloat(bean))
	}

	final override void visit(DoubleProperty prop) {
		visit(prop)
		visit(prop, prop.getDouble(bean))
	}

	final override void visit(ObjectProperty prop) {
		visit(prop)
		val obj = prop.getObject(bean)
		if (obj === null) {
			visitNull(prop)
		} else if (obj instanceof _Entity) {
			visitEntity(prop, obj)
		} else if (obj instanceof _Bean) {
			visitBean(prop, obj)
		} else {
			visitObject(prop, obj)
		}
	}

	/** Visit byte properties */
	protected def void visit(ByteProperty prop, byte value) {
		visitNumber(prop, value)
	}

	/** Visit char properties */
	protected def void visit(CharacterProperty prop, char value) {
		visitNumber(prop, value)
	}

	/** Visit short properties */
	protected def void visit(ShortProperty prop, short value) {
		visitNumber(prop, value)
	}

	/** Visit int properties */
	protected def void visit(IntegerProperty prop, int value) {
		visitNumber(prop, value)
	}

	/** Visit long properties */
	protected def void visit(LongProperty prop, long value) {
		visitNumber(prop, value)
	}

	/** Visit float properties */
	protected def void visit(FloatProperty prop, float value) {
		visitNumber(prop, value)
	}

	/** Visit double properties */
	protected def void visit(DoubleProperty prop, double value) {
		visitNumber(prop, value)
	}

	/** Visit ObjectProperty with null value */
	protected def void visitNull(ObjectProperty prop) {
		visitObject(prop, null)
	}

	/** Visit ObjectProperty with Entity value */
	protected def void visitEntity(ObjectProperty prop, _Entity value) {
		visitBean(prop, value)
	}

	/** Visit ObjectProperty with Bean value */
	protected def void visitBean(ObjectProperty prop, _Bean value) {
		visitObject(prop, value)
		visit(value)
	}

	/** Called for beans */
	public def void visit(_Bean bean) {
		if (bean !== null) {
			val before = this.bean
			this.bean = bean
			for (p : bean.metaType.inheritedProperties) {
				p.accept(this)
			}
			this.bean = before
		}
	}

	/** Called for all properties */
	protected def void visit(Property prop) {
		// NOP
	}

	/** Visit boolean properties */
	protected def void visit(BooleanProperty prop, boolean value) {
		// NOP
	}

	/**
	 * All integral primitive properties end up delegating here,
	 * Including boolean.
	 */
	protected def void visitNumber(PrimitiveProperty prop, long value) {
		// NOP
	}

	/**
	 * All floating-point primitive properties end up delegating here,
	 */
	protected def void visitNumber(PrimitiveProperty prop, double value) {
		// NOP
	}

	/**
	 * Visit ObjectProperty with Object value.
	 *
	 * All Object properties end up delegating here.
	 */
	protected def void visitObject(ObjectProperty prop, Object value) {
		// NOP
	}
}