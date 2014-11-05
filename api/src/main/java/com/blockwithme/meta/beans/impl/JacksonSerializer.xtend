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

import com.blockwithme.meta.AbstractPropertyVisitor
import com.blockwithme.meta.BooleanProperty
import com.blockwithme.meta.IIntegralPrimitiveProperty
import com.blockwithme.meta.IRealPrimitiveProperty
import com.blockwithme.meta.ObjectProperty
import com.blockwithme.meta.beans._Bean
import com.fasterxml.jackson.core.JsonEncoding
import com.fasterxml.jackson.core.JsonFactory
import com.fasterxml.jackson.core.JsonGenerator
import com.google.common.io.CharStreams
import java.io.File
import java.io.OutputStream
import java.io.Writer
import java.math.BigDecimal
import java.math.BigInteger
import java.util.IdentityHashMap
import java.util.Objects
import com.blockwithme.meta.Type
import com.blockwithme.meta.beans.Bean
import com.blockwithme.meta.Kind
import com.blockwithme.meta.JavaMeta

/**
 * A PropertyVisitor that produces a Jackson (normally JSON) output for beans.
 *
 * @author monster
 */
class JacksonSerializer extends AbstractPropertyVisitor {

	/** JsonFactory */
	public static val FACTORY = new JsonFactory()

	/** Property name for the type of an object/beans */
	public static val CLASS = "class"

	/** Property name for the "position" of an object */
	public static val POSITION = "#"

	/** Property name for the "content" of an object of unknown type */
	public static val CONTENT = "*"

	/** Keeps track of circular references */
	val cache = new IdentityHashMap<Object,Integer>

	/** Generator */
	public val JsonGenerator generator

	/** Output of generator. Could be anything, including null. */
	public val Object output

	/** Creates the JSONPropertyVisitor */
	new (JsonGenerator generator, Object output) {
		this.generator = Objects.requireNonNull(generator, "generator")
		this.output = output
	}

    /**
     * Called before visiting an Object instance.
     * @param type The type of the instance.
     * @param instance The instance.
     */
    protected override beforeVisitInstance(Type<?> type, Object instance) {
    	if (instance !== null) {
    		if (instance instanceof Bean) {
    			appendObjectStart(instance)
			} else {
				visitNonBeanValue(instance)
				false
			}
		} else {
			false
		}
    }

    /**
     * Called after visiting an Object instance.
     * @param type The type of the instance.
     * @param instance The instance.
     */
    protected override void afterVisitInstance(Type<?> type, Object instance, boolean visited) {
		if (visited)
			appendObjectEnd
		else if (instance === null) {
    		generator.writeNull
    	}
    }

	/** Append Object start. Returns true if this is a new Object */
	protected def boolean appendObjectStart(Object obj) {
		generator.writeStartObject()
		var key = cache.get(obj)
		if (key === null) {
			key = cache.size
			cache.put(obj, key)
			generator.writeNumberField(POSITION, key)
			if (!(obj instanceof Class)) {
				generator.writeFieldName(CLASS)
				// We have no special serialization for class, as the default is OK,
				// And if we actually have a class as a field value, then it still
				// all works consistently.
				writeUnknownObject(obj.class)
			}
			true
		} else {
			generator.writeNumberField(POSITION, key)
			false
		}
	}

	/** Append Object end */
	protected def void appendObjectEnd() {
		generator.writeEndObject()
	}

	/** Called for all properties */
	protected override void visitProperty(String propName) {
		generator.writeFieldName(propName)
	}

	/** Visit boolean properties */
	protected override void visitValue(BooleanProperty prop, boolean value) {
		generator.writeBoolean(value)
	}

	/**
	 * All integral primitive properties end up delegating here,
	 * Including boolean.
	 */
	protected override void visitNumberValue(IIntegralPrimitiveProperty prop, long value) {
		generator.writeNumber(value)
	}

	/**
	 * All floating-point primitive properties end up delegating here,
	 */
	protected override void visitNumberValue(IRealPrimitiveProperty prop, double value) {
		generator.writeNumber(value)
	}

	/**
	 * Visit ObjectProperty with Object value.
	 *
	 * All Object properties end up delegating here.
	 */
	private def void visitNonBeanValue(Object value) {
		if (value === null) {
			generator.writeNull
		} else if (value instanceof String) {
			generator.writeString(value)
		} else if (value instanceof CharSequence) {
			generator.writeString(value.toString)
		} else if (value instanceof Enum<?>) {
			generator.writeString(value.name)
		} else if (value instanceof Boolean) {
			generator.writeBoolean(value.booleanValue)
		} else if (value instanceof Number) {
			if (value.class.package.name == "java.lang") {
				val number = value as Number
				val lvalue = number.longValue
				val dvalue = number.doubleValue
				if (dvalue === lvalue) {
					generator.writeNumber(lvalue)
				} else {
					generator.writeNumber(dvalue)
				}
			} else if (value instanceof BigInteger) {
				generator.writeNumber(value)
			} else if (value instanceof BigDecimal) {
				generator.writeNumber(value)
			} else {
				// What kind of Number is that?
				writeUnknownObject(value)
			}
		} else if (value.class.array) {
			writeArrayObject(value)
		} else {
			// "Class" comes here by Design.
			writeUnknownObject(value)
		}
	}

	protected def void writeArrayObject(Object value) {
		if (appendObjectStart(value)) {
			val compomentType = value.class.componentType
			if (compomentType.primitive) {
				if (compomentType == Boolean.TYPE) {
					val array = value as boolean[]
					if (array.length > 0) {
						generator.writeArrayFieldStart(CONTENT)
						for (v : array) {
							generator.writeBoolean(v)
						}
						generator.writeEndArray
					}
				} else if (compomentType == Byte.TYPE) {
					val array = value as byte[]
					if (array.length > 0) {
						generator.writeArrayFieldStart(CONTENT)
						for (v : array) {
							generator.writeNumber(v)
						}
						generator.writeEndArray
					}
				} else if (compomentType == Character.TYPE) {
					val array = value as char[]
					if (array.length > 0) {
						generator.writeArrayFieldStart(CONTENT)
						for (v : array) {
							generator.writeNumber(v)
						}
						generator.writeEndArray
					}
				} else if (compomentType == Short.TYPE) {
					val array = value as short[]
					if (array.length > 0) {
						generator.writeArrayFieldStart(CONTENT)
						for (v : array) {
							generator.writeNumber(v)
						}
						generator.writeEndArray
					}
				} else if (compomentType == Integer.TYPE) {
					val array = value as int[]
					if (array.length > 0) {
						generator.writeArrayFieldStart(CONTENT)
						for (v : array) {
							generator.writeNumber(v)
						}
						generator.writeEndArray
					}
				} else if (compomentType == Long.TYPE) {
					val array = value as long[]
					if (array.length > 0) {
						generator.writeArrayFieldStart(CONTENT)
						for (v : array) {
							generator.writeNumber(v)
						}
						generator.writeEndArray
					}
				} else if (compomentType == Float.TYPE) {
					val array = value as float[]
					if (array.length > 0) {
						generator.writeArrayFieldStart(CONTENT)
						for (v : array) {
							generator.writeNumber(v)
						}
						generator.writeEndArray
					}
				} else if (compomentType == Double.TYPE) {
					val array = value as double[]
					if (array.length > 0) {
						generator.writeArrayFieldStart(CONTENT)
						for (v : array) {
							generator.writeNumber(v)
						}
						generator.writeEndArray
					}
				} else {
					throw new IllegalStateException("Unknown primitive type: "+compomentType)
				}
			} else {
				val array = value as Object[]
				if (array.length > 0) {
					generator.writeArrayFieldStart(CONTENT)
					val contentType = tryResolveType(compomentType)
					for (v : array) {
						if (v === null)
							generator.writeNull
						else
							visitNonNullValueByContentType(contentType, v)
					}
					generator.writeEndArray
				}
			}
		}
		appendObjectEnd()
	}

	protected def void writeUnknownObject(Object value) {
		if (appendObjectStart(value)) {
			generator.writeFieldName(CONTENT)
			generator.writeString(value.toString())
		}
		appendObjectEnd()
	}

	/** Creates a new serializer from a Writer */
	def static JacksonSerializer newSerializer(Writer out) {
		new JacksonSerializer(FACTORY.createGenerator(out), out)
	}

	/** Creates a new serializer from an OutputStream */
	def static JacksonSerializer newSerializer(OutputStream out) {
		new JacksonSerializer(FACTORY.createGenerator(out), out)
	}

	/** Creates a new serializer from a File */
	def static JacksonSerializer newSerializer(File out) {
		new JacksonSerializer(FACTORY.createGenerator(out, JsonEncoding.UTF8), out)
	}

	/** Creates a new serializer from a File */
	def static JacksonSerializer newSerializer(String out) {
		newSerializer(new File(out))
	}

	/** Creates a new serializer using a new StringWriter */
	def static JacksonSerializer newSerializer(Appendable out) {
		if (out instanceof Writer) {
			newSerializer(out)
		} else if (out instanceof OutputStream) {
			newSerializer(out as OutputStream)
		} else {
			// out instanceof StringBuilder?
			new JacksonSerializer(FACTORY.createGenerator(CharStreams.asWriter(out)), out)
		}
	}
}