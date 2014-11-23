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
package com.blockwithme.meta

import java.util.ArrayList

/**
 * A base class for PropertyVisitors.
 *
 * Visiting a "Typed" object causes all it's inheritedProperties to be visited.
 *
 * TODO The visitor should support some basic data-transformations, like class-to-string,
 * enum-to-string, enum-to-int, ...
 *
 * TODO The visitor should support a choice between "internal" (Bean impl) and "external" (Bean interface) values.
 *
 * TODO The visitor should give access to the "parent" object.
 *
 * TODO The visitor should offer a choice of automatically skipping default values.
 *
 * TODO The visitor should offer to only visit Beans.
 *
 * @author monster
 */
abstract class AbstractPropertyVisitor implements PropertyVisitor {
	/** All the Hierarchies */
	val hierarchies = new ArrayList<Hierarchy>

	/** The currently visited object */
	private Object obj

    /**
     * Visits an Object instance.
     * @param type The type of the instance. Cannot be null.
     * @param instance The instance. Cannot be null.
     */
    final def override visit(Type<?> type, Object instance) {
    	recordHierarchy(type)
    	val visited = beforeVisitInstance(type, instance)
    	if (visited) {
			for (p : type.inheritedProperties) {
				obj = instance
				try {
					p.accept(this)
				} finally {
					obj = null
				}
			}
		}
    	afterVisitInstance(type, instance, visited)
	}

	final override void visit(BooleanProperty prop) {
		visitProperty(prop)
		visitValue(prop, prop.getBoolean(obj))
		afterVisitProperty(prop)
	}

	final override void visit(ByteProperty prop) {
		visitProperty(prop)
		visitValue(prop, prop.getByte(obj))
		afterVisitProperty(prop)
	}

	final override void visit(CharacterProperty prop) {
		visitProperty(prop)
		visitValue(prop, prop.getChar(obj))
		afterVisitProperty(prop)
	}

	final override void visit(ShortProperty prop) {
		visitProperty(prop)
		visitValue(prop, prop.getShort(obj))
		afterVisitProperty(prop)
	}

	final override void visit(IntegerProperty prop) {
		visitProperty(prop)
		visitValue(prop, prop.getInt(obj))
		afterVisitProperty(prop)
	}

	final override void visit(LongProperty prop) {
		visitProperty(prop)
		visitValue(prop, prop.getLong(obj))
		afterVisitProperty(prop)
	}

	final override void visit(FloatProperty prop) {
		visitProperty(prop)
		visitValue(prop, prop.getFloat(obj))
		afterVisitProperty(prop)
	}

	final override void visit(DoubleProperty prop) {
		visitProperty(prop)
		visitValue(prop, prop.getDouble(obj))
		afterVisitProperty(prop)
	}

	final override void visit(ObjectProperty prop) {
		visitProperty(prop)
		visitValue(prop, prop.getObject(obj))
		afterVisitProperty(prop)
	}

    /**
     * Called before visiting an Object instance.
     * @param type The type of the instance.
     * @param instance The instance.
     */
    protected def beforeVisitInstance(Type<?> type, Object instance) {
    	(instance !== null)
    }

    /**
     * Called after visiting an Object instance.
     * @param type The type of the instance.
     * @param instance The instance.
     * @param visited did we visit the instance?
     */
    protected def void afterVisitInstance(Type<?> type, Object instance, boolean visited) {
    	// NOP
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
		if (value !== null) {
			val contentType = prop.findContentType()
			if (contentType === null) {
				throw new IllegalStateException("Cannot find Type of ObjectProperty "+prop)
			}
			visitNonNullValueByContentType(contentType, value)
		} else {
			visitNullValue(prop)
		}
	}

	/** Visit Properties with their non-null value */
	protected final def void visitNonNullValueByContentType(Type<?> contentType, Object value) {
		val valueType = if (contentType.isExactTypeOf(value)) {
			contentType
		} else {
			recordHierarchy(contentType)
			if (value instanceof TypeOwner) {
				val result = value.metaType
				if (contentType !== result) {
					recordHierarchy(result)
				}
				result
			}
		}
		visit(valueType, value)
	}

	/** Records the Hierarchy */
	private def void recordHierarchy(Hierarchy th) {
		// hierarchies
		for (h : hierarchies) {
			if ((h === th) || h.dependencies.contains(th)) {
				return
			}
		}
		val iter = hierarchies.iterator
		val deps = newArrayList(th.dependencies)
		while (iter.hasNext) {
			val h = iter.next
			if (deps.contains(h)) {
				iter.remove
			}
		}
		hierarchies.add(th)
	}

	/** Records the Hierarchy of an object */
	private def void recordHierarchy(MetaBase<?> type) {
		if (type !== null) {
			recordHierarchy(type.hierarchy)
		}
	}

	/** Resolves the type of an Object. Fails if not found. */
	private def Type<?> resolveType2(Class<?> valueType) {
		for (h : hierarchies) {
			val result = h.findType(valueType)
			if (result !== null) {
				return result
			}
		}
		val ann = valueType.getAnnotation(TypeImplemented)
		if (ann !== null) {
			val implemented = ann.implemented
			for (h : hierarchies) {
				val result = h.findType(implemented)
				if (result !== null) {
					return result
				}
			}
		}
		null
	}

	/** Resolves the type of an Object. Fails if not found. */
	protected def Type<?> resolveType(Class<?> valueType) {
		val result = resolveType2(valueType)
		if (result === null) {
			throw new IllegalArgumentException("Cannot resolve type of "+valueType+" in "+hierarchies)
		}
		result
	}

	/** Resolves the type of an Object. Returns OBJECT if not found. */
	protected def Type<?> tryResolveType(Class<?> valueType) {
		val result = resolveType2(valueType)
		if (result === null) {
			return JavaMeta.OBJECT
		}
		result
	}

	/** Visit Object properties with null value */
	protected final def void visitNullValue(ObjectProperty prop) {
		// NOP
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
}