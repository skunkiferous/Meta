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
import com.blockwithme.meta.IIntegralPrimitiveProperty
import com.blockwithme.meta.IRealPrimitiveProperty
import com.blockwithme.meta.IntegerProperty
import com.blockwithme.meta.LongProperty
import com.blockwithme.meta.ObjectProperty
import com.blockwithme.meta.Property
import com.blockwithme.meta.ShortProperty
import com.blockwithme.meta.beans.BeanVisitable
import com.blockwithme.meta.beans.BeanVisitor
import com.blockwithme.meta.beans._Bean

/**
 * A base class for BeanVisitors.
 *
 * Visiting a Bean causes all it's inheritedProperties to be visited.
 *
 * @author monster
 */
abstract class AbstractBeanVisitor implements BeanVisitor {
	/** The currently visited bean */
	private _Bean bean

	/** Called for beans */
	public override void visit(_Bean bean) {
		for (p : bean.metaType.inheritedProperties) {
			this.bean = bean
			try {
				p.accept(this)
			} finally {
				this.bean = null
			}
		}
	}

  /**
   * Defines the start of the visit of a non-Bean.
   *
   * If it returns true, then the non-Bean should also write it's properties.
   * In all case, it should then call endVisitNonBean()
   */
  override boolean startVisitNonBean(Object nonBean) { true }

  /**
   * Defines the end of the visit of a non-Bean.
   */
  override void endVisitNonBean(Object nonBean) {}

	final override void visit(BooleanProperty prop) {
		visitProperty(prop)
		visitValue(prop, prop.getBoolean(bean))
		afterVisitProperty(prop)
	}

	final override void visit(ByteProperty prop) {
		visitProperty(prop)
		visitValue(prop, prop.getByte(bean))
		afterVisitProperty(prop)
	}

	final override void visit(CharacterProperty prop) {
		visitProperty(prop)
		visitValue(prop, prop.getChar(bean))
		afterVisitProperty(prop)
	}

	final override void visit(ShortProperty prop) {
		visitProperty(prop)
		visitValue(prop, prop.getShort(bean))
		afterVisitProperty(prop)
	}

	final override void visit(IntegerProperty prop) {
		visitProperty(prop)
		visitValue(prop, prop.getInt(bean))
		afterVisitProperty(prop)
	}

	final override void visit(LongProperty prop) {
		visitProperty(prop)
		visitValue(prop, prop.getLong(bean))
		afterVisitProperty(prop)
	}

	final override void visit(FloatProperty prop) {
		visitProperty(prop)
		visitValue(prop, prop.getFloat(bean))
		afterVisitProperty(prop)
	}

	final override void visit(DoubleProperty prop) {
		visitProperty(prop)
		visitValue(prop, prop.getDouble(bean))
		afterVisitProperty(prop)
	}

	final override void visit(ObjectProperty prop) {
		visitProperty(prop)
		visitValue(prop, prop.getObject(bean))
		afterVisitProperty(prop)
	}

	/** Visit non-Bean boolean properties with their value */
	final override void visitNonBeanProperty(String propName, boolean value) {
		visitProperty(propName)
		visitValue(null, value)
		afterVisitProperty(propName)
	}

	/** Visit non-Bean byte properties with their value */
	final override void visitNonBeanProperty(String propName, byte value) {
		visitProperty(propName)
		visitValue(null as ByteProperty, value)
		afterVisitProperty(propName)
	}

	/** Visit non-Bean char properties with their value */
	final override void visitNonBeanProperty(String propName, char value) {
		visitProperty(propName)
		visitValue(null as CharacterProperty, value)
		afterVisitProperty(propName)
	}

	/** Visit non-Bean short properties with their value */
	final override void visitNonBeanProperty(String propName, short value) {
		visitProperty(propName)
		visitValue(null as ShortProperty, value)
		afterVisitProperty(propName)
	}

	/** Visit non-Bean int properties with their value */
	final override void visitNonBeanProperty(String propName, int value) {
		visitProperty(propName)
		visitValue(null as IntegerProperty, value)
		afterVisitProperty(propName)
	}

	/** Visit non-Bean long properties with their value */
	final override void visitNonBeanProperty(String propName, long value) {
		visitProperty(propName)
		visitValue(null as LongProperty, value)
		afterVisitProperty(propName)
	}

	/** Visit non-Bean float properties with their value */
	final override void visitNonBeanProperty(String propName, float value) {
		visitProperty(propName)
		visitValue(null as FloatProperty, value)
		afterVisitProperty(propName)
	}

	/** Visit non-Bean double properties with their value */
	final override void visitNonBeanProperty(String propName, double value) {
		visitProperty(propName)
		visitValue(null as DoubleProperty, value)
		afterVisitProperty(propName)
	}

	/** Visit non-Bean Object properties with their value */
	final override void visitNonBeanProperty(String propName, Object value) {
		visitProperty(propName)
		visitValue(null, value)
		afterVisitProperty(propName)
	}

	/** Called before visiting the value of a Property. */
	protected def void visitProperty(Property prop) {
		visitProperty(prop.simpleName)
	}

	/** Called after visiting the value of a Property. */
	protected def void afterVisitProperty(Property prop) {
		afterVisitProperty(prop.simpleName)
	}

	/** Called before visiting the value of a Property. */
	protected def void visitProperty(String propName) {
		// NOP
	}

	/** Called after visiting the value of a Property. */
	protected def void afterVisitProperty(String propName) {
		// NOP
	}

	/** Visit boolean properties with their value */
	protected def void visitValue(BooleanProperty prop, boolean value) {
		// NOP
	}

	/** Visit byte properties with their value */
	protected def void visitValue(ByteProperty prop, byte value) {
		visitNumberValue(prop, value)
	}

	/** Visit char properties with their value */
	protected def void visitValue(CharacterProperty prop, char value) {
		visitNumberValue(prop, value)
	}

	/** Visit short properties with their value */
	protected def void visitValue(ShortProperty prop, short value) {
		visitNumberValue(prop, value)
	}

	/** Visit int properties with their value */
	protected def void visitValue(IntegerProperty prop, int value) {
		visitNumberValue(prop, value)
	}

	/** Visit long properties with their value */
	protected def void visitValue(LongProperty prop, long value) {
		visitNumberValue(prop, value)
	}

	/** Visit float properties with their value */
	protected def void visitValue(FloatProperty prop, float value) {
		visitNumberValue(prop, value)
	}

	/** Visit double properties with their value */
	protected def void visitValue(DoubleProperty prop, double value) {
		visitNumberValue(prop, value)
	}

	/** Visit Object properties with their value */
	protected final def void visitValue(ObjectProperty prop, Object value) {
		if (value instanceof BeanVisitable) {
			value.accept(this)
		} else {
			visitNonBeanValue(prop, value)
		}
	}

	/**
	 * All integral primitive properties end up delegating here,
	 * Including boolean.
	 */
	protected def void visitNumberValue(IIntegralPrimitiveProperty prop, long value) {
		// NOP
	}

	/**
	 * All floating-point primitive properties end up delegating here,
	 */
	protected def void visitNumberValue(IRealPrimitiveProperty prop, double value) {
		// NOP
	}

	/**
	 * Visit ObjectProperty with non-Bean value.
	 *
	 * All Object properties end up delegating here.
	 */
	protected def void visitNonBeanValue(ObjectProperty prop, Object value) {
		// NOP
	}
}