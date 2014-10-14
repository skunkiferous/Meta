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
import com.blockwithme.meta.ShortProperty
import com.blockwithme.meta.beans.Interceptor
import com.blockwithme.meta.beans._Bean
import java.util.HashSet
import com.blockwithme.meta.beans.Entity
import com.blockwithme.meta.Type
import com.blockwithme.meta.beans.annotations.ValidationException

/**
 * Singleton, used for all normal "beans".
 * Simply delegates back to the bean, marking it as dirty if needed.
 *
 * TODO Add validators to all properties, and call the in setXXX
 *
 * @author monster
 */
class DefaultInterceptor implements Interceptor {
	/** Valid Object property types, beyond Beans. */
	static val VALID_PROPERTY_TYPES = new HashSet<Class<?>>(newArrayList(
		Boolean, Byte, Character, Short, Integer, Float, Double, Long, String, Class
		// Mutable types, like int[], cause issues, because we cannot track the changes.
	))

    /** Default instance */
    public static val INSTANCE = new DefaultInterceptor()

	override boolean getBooleanProperty(_Bean instance, BooleanProperty<?, ?, ?> prop, boolean value) {
        value
	}

	override boolean setBooleanProperty(_Bean instance, BooleanProperty<?, ?, ?> prop, boolean oldValue, boolean newValue) {
        if (oldValue !== newValue) {
            val metaType = instance.metaType as Type
            var String error = null
            for (v : prop.getValidators(metaType)) {
            	val msg = v.beforeBooleanPropertyChange(instance, prop, oldValue, newValue)
            	if (msg !== null) {
            		if (error === null) {
            			error = msg
            		} else {
            			error = error + " " + msg
            		}
            	}
            }
            if (error !== null) {
            	throw new ValidationException(error)
            }
            for (l : prop.getListeners(metaType)) {
            	l.afterBooleanPropertyChangeValidation(instance, prop, oldValue, newValue)
            }
            instance.setSelected(prop)
        }
        newValue
	}

	override byte getByteProperty(_Bean instance, ByteProperty<?, ?, ?> prop, byte value) {
        value
	}

	override byte setByteProperty(_Bean instance, ByteProperty<?, ?, ?> prop, byte oldValue, byte newValue) {
        if (oldValue !== newValue) {
            val metaType = instance.metaType as Type
            var String error = null
            for (v : prop.getValidators(metaType)) {
            	val msg = v.beforeBytePropertyChange(instance, prop, oldValue, newValue)
            	if (msg !== null) {
            		if (error === null) {
            			error = msg
            		} else {
            			error = error + " " + msg
            		}
            	}
            }
            if (error !== null) {
            	throw new ValidationException(error)
            }
            for (l : prop.getListeners(metaType)) {
            	l.afterBytePropertyChangeValidation(instance, prop, oldValue, newValue)
            }
            instance.setSelected(prop)
        }
        newValue
	}

	override char getCharacterProperty(_Bean instance, CharacterProperty<?, ?, ?> prop, char value) {
        value
	}

	override char setCharacterProperty(_Bean instance, CharacterProperty<?, ?, ?> prop, char oldValue, char newValue) {
        if (oldValue !== newValue) {
            val metaType = instance.metaType as Type
            var String error = null
            for (v : prop.getValidators(metaType)) {
            	val msg = v.beforeCharacterPropertyChange(instance, prop, oldValue, newValue)
            	if (msg !== null) {
            		if (error === null) {
            			error = msg
            		} else {
            			error = error + " " + msg
            		}
            	}
            }
            if (error !== null) {
            	throw new ValidationException(error)
            }
            for (l : prop.getListeners(metaType)) {
            	l.afterCharacterPropertyChangeValidation(instance, prop, oldValue, newValue)
            }
            instance.setSelected(prop)
        }
        newValue
	}

	override short getShortProperty(_Bean instance, ShortProperty<?, ?, ?> prop, short value) {
        value
	}

	override short setShortProperty(_Bean instance, ShortProperty<?, ?, ?> prop, short oldValue, short newValue) {
        if (oldValue !== newValue) {
            val metaType = instance.metaType as Type
            var String error = null
            for (v : prop.getValidators(metaType)) {
            	val msg = v.beforeShortPropertyChange(instance, prop, oldValue, newValue)
            	if (msg !== null) {
            		if (error === null) {
            			error = msg
            		} else {
            			error = error + " " + msg
            		}
            	}
            }
            if (error !== null) {
            	throw new ValidationException(error)
            }
            for (l : prop.getListeners(metaType)) {
            	l.afterShortPropertyChangeValidation(instance, prop, oldValue, newValue)
            }
            instance.setSelected(prop)
        }
        newValue
	}

	override int getIntegerProperty(_Bean instance, IntegerProperty<?, ?, ?> prop, int value) {
        value
	}

	override int setIntegerProperty(_Bean instance, IntegerProperty<?, ?, ?> prop, int oldValue, int newValue) {
        if (oldValue !== newValue) {
            val metaType = instance.metaType as Type
            var String error = null
            for (v : prop.getValidators(metaType)) {
            	val msg = v.beforeIntegerPropertyChange(instance, prop, oldValue, newValue)
            	if (msg !== null) {
            		if (error === null) {
            			error = msg
            		} else {
            			error = error + " " + msg
            		}
            	}
            }
            if (error !== null) {
            	throw new ValidationException(error)
            }
            for (l : prop.getListeners(metaType)) {
            	l.afterIntegerPropertyChangeValidation(instance, prop, oldValue, newValue)
            }
            instance.setSelected(prop)
        }
        newValue
	}

	override float getFloatProperty(_Bean instance, FloatProperty<?, ?, ?> prop, float value) {
        value
	}

	override float setFloatProperty(_Bean instance, FloatProperty<?, ?, ?> prop, float oldValue, float newValue) {
        if (oldValue !== newValue) {
            val metaType = instance.metaType as Type
            var String error = null
            for (v : prop.getValidators(metaType)) {
            	val msg = v.beforeFloatPropertyChange(instance, prop, oldValue, newValue)
            	if (msg !== null) {
            		if (error === null) {
            			error = msg
            		} else {
            			error = error + " " + msg
            		}
            	}
            }
            if (error !== null) {
            	throw new ValidationException(error)
            }
            for (l : prop.getListeners(metaType)) {
            	l.afterFloatPropertyChangeValidation(instance, prop, oldValue, newValue)
            }
            instance.setSelected(prop)
        }
        newValue
	}

	override double getDoubleProperty(_Bean instance, DoubleProperty<?, ?, ?> prop, double value) {
        value
	}

	override double setDoubleProperty(_Bean instance, DoubleProperty<?, ?, ?> prop, double oldValue, double newValue) {
        if (oldValue !== newValue) {
            val metaType = instance.metaType as Type
            var String error = null
            for (v : prop.getValidators(metaType)) {
            	val msg = v.beforeDoublePropertyChange(instance, prop, oldValue, newValue)
            	if (msg !== null) {
            		if (error === null) {
            			error = msg
            		} else {
            			error = error + " " + msg
            		}
            	}
            }
            if (error !== null) {
            	throw new ValidationException(error)
            }
            for (l : prop.getListeners(metaType)) {
            	l.afterDoublePropertyChangeValidation(instance, prop, oldValue, newValue)
            }
            instance.setSelected(prop)
        }
        newValue
	}

	override long getLongProperty(_Bean instance, LongProperty<?, ?, ?> prop, long value) {
        value
	}

	override long setLongProperty(_Bean instance, LongProperty<?, ?, ?> prop, long oldValue, long newValue) {
        if (oldValue !== newValue) {
            val metaType = instance.metaType as Type
            var String error = null
            for (v : prop.getValidators(metaType)) {
            	val msg = v.beforeLongPropertyChange(instance, prop, oldValue, newValue)
            	if (msg !== null) {
            		if (error === null) {
            			error = msg
            		} else {
            			error = error + " " + msg
            		}
            	}
            }
            if (error !== null) {
            	throw new ValidationException(error)
            }
            for (l : prop.getListeners(metaType)) {
            	l.afterLongPropertyChangeValidation(instance, prop, oldValue, newValue)
            }
            instance.setSelected(prop)
        }
        newValue
	}

	override <E> getObjectProperty(_Bean instance, ObjectProperty<?, E,?,?> prop, E value) {
        value
	}

	override <E> setObjectProperty(_Bean instance, ObjectProperty<?, E,?,?> prop, E oldValue, E newValue) {
        if (oldValue !== newValue) {
            val metaType = instance.metaType as Type
            var String error = null
            for (v : prop.getValidators(metaType)) {
            	val msg = v.beforeObjectPropertyChange(instance, prop, oldValue, newValue)
            	if (msg !== null) {
            		if (error === null) {
            			error = msg
            		} else {
            			error = error + " " + msg
            		}
            	}
            }
            if (error !== null) {
            	throw new ValidationException(error)
            }
			val result = objectPropertyChanged(instance, prop.fullName,
				instance.indexOfProperty(prop), oldValue, newValue)
            for (l : prop.getListeners(metaType)) {
            	l.afterObjectPropertyChangeValidation(instance, prop, oldValue, result)
            }
	        result
        } else {
        	if ((newValue == null) && !prop.nullAllowed) {
        		throw new ValidationException(prop.fullName+" cannot be null")
        	}
        	newValue
        }
	}

	protected def <E> objectPropertyChanged(_Bean instance, Object propId,
		int propIndex, E oldValue, E newValue) {
        if (oldValue !== newValue) {
            // Note: oldValue must be cleared *before* checking for cycles.
            if (oldValue instanceof _Bean) {
            	oldValue.setParentBeanAndKey(null, null);
            }
            if (newValue instanceof _Bean) {
            	if (!(newValue instanceof Entity) && !newValue.immutable) {
	            	if (instance.hasSameRoot(newValue)) {
	            		// Undo changes
			            if (oldValue instanceof _Bean) {
			            	oldValue.setParentBeanAndKey(instance, propId)
			            }
			            throw new IllegalStateException("Cycles not permitted on "
			            	+propId+" of "+instance.class.name)
	            	}
	            	newValue.setParentBeanAndKey(instance, propId)
	            	newValue.setSelectionRecursive()
				}
            } else if (newValue !== null) {
            	validateObjectType(newValue)
            }
            instance.setSelected(propIndex)
        }
        newValue
	}

	def validateObjectType(Object e) {
		if (!(e.class.enum || VALID_PROPERTY_TYPES.contains(e.class))) {
			if (!e.class.annotations.exists[it.annotationType==Data])
				throw new ValidationException("Property values of type "
					+e.class+" not (yet) supported")
		}
	}

}