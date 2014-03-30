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
import com.blockwithme.meta.ObjectProperty
import com.blockwithme.meta.PrimitiveProperty
import com.blockwithme.meta.Property
import com.blockwithme.meta.beans._Bean
import com.blockwithme.meta.beans._Entity
import com.fasterxml.jackson.core.JsonFactory
import com.fasterxml.jackson.core.JsonGenerator
import java.math.BigDecimal
import java.math.BigInteger
import java.util.IdentityHashMap
import java.util.Objects
import java.io.Writer
import java.io.OutputStream
import java.io.File
import com.fasterxml.jackson.core.JsonEncoding
import com.google.common.io.CharStreams

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

	/** Append Object start. Returns true if this is a new Object */
	protected def boolean appendObjectStart(Object obj) {
		generator.writeStartObject()
		var key = cache.get(obj)
		if (key === null) {
			key = cache.size
			cache.put(obj, key)
			generator.writeNumberField(POSITION, key)
			generator.writeStringField(CLASS, obj.class.name)
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

	/** Called for beans */
	public override void visit(_Bean bean) {
		if (bean !== null) {
			if (appendObjectStart(bean)) {
				super.visit(bean)
				appendObjectEnd()
			}
		} else {
			generator.writeNull
		}
	}

	/** Called for all properties */
	protected override void visit(Property prop) {
		generator.writeFieldName(prop.simpleName)
	}

	/** Visit ObjectProperty with null value */
	protected override void visitNull(ObjectProperty prop) {
		generator.writeNull
	}

	/** Visit boolean properties */
	protected override void visit(BooleanProperty prop, boolean value) {
		generator.writeBoolean(value)
	}

	/**
	 * All integral primitive properties end up delegating here,
	 * Including boolean.
	 */
	protected override void visitNumber(PrimitiveProperty prop, long value) {
		generator.writeNumber(value)
	}

	/**
	 * All floating-point primitive properties end up delegating here,
	 */
	protected override void visitNumber(PrimitiveProperty prop, double value) {
		generator.writeNumber(value)
	}

	/** Visit ObjectProperty with Entity value */
	protected override void visitEntity(ObjectProperty prop, _Entity value) {
		// TODO Probably not the best solution...
		generator.writeString(value.getEntityContext().getIDAsString(value))
	}

	/**
	 * Visit ObjectProperty with Object value.
	 *
	 * All Object properties end up delegating here.
	 */
	protected override void visitObject(ObjectProperty prop, Object value) {
		// Cannot be null!
		if (value instanceof String) {
			generator.writeString(value)
		} else if (value instanceof CharSequence) {
			generator.writeString(value.toString)
		} else if (value instanceof Class<?>) {
			generator.writeString(value.name)
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
				// What is that?
				writeUnknownObject(value)
			}
		} else if (value.class.array) {
			writeArrayObject(value)
		} else {
			writeUnknownObject(value)
		}
	}

	protected def void writeArrayObject(Object value) {
		if (appendObjectStart(value)) {
			generator.writeFieldName(CONTENT)
			val compomentType = value.class.componentType
			val buf = new StringBuilder
			var sep = ""
			buf.append("[")
			if (compomentType.primitive) {
				if (compomentType == Boolean.TYPE) {
					for (v : value as boolean[]) {
						buf.append(sep)
						sep = ","
						buf.append(v)
					}
				} else if (compomentType == Byte.TYPE) {
					for (v : value as byte[]) {
						buf.append(sep)
						sep = ","
						buf.append(v as int)
					}
				} else if (compomentType == Character.TYPE) {
					for (v : value as char[]) {
						buf.append(sep)
						sep = ","
						buf.append(v)
					}
				} else if (compomentType == Short.TYPE) {
					for (v : value as short[]) {
						buf.append(sep)
						sep = ","
						buf.append(v as int)
					}
				} else if (compomentType == Integer.TYPE) {
					for (v : value as int[]) {
						buf.append(sep)
						sep = ","
						buf.append(v)
					}
				} else if (compomentType == Long.TYPE) {
					for (v : value as long[]) {
						buf.append(sep)
						sep = ","
						buf.append(v)
					}
				} else if (compomentType == Float.TYPE) {
					for (v : value as float[]) {
						buf.append(sep)
						sep = ","
						buf.append(v)
					}
				} else if (compomentType == Double.TYPE) {
					for (v : value as double[]) {
						buf.append(sep)
						sep = ","
						buf.append(v)
					}
				} else {
					throw new IllegalStateException("Unknown primitive type: "+compomentType)
				}
			} else {
				for (v : value as Object[]) {
					buf.append(sep)
					sep = ","
					buf.append(v)
				}
			}
			buf.append("]")
			generator.writeString(buf.toString())
			appendObjectEnd()
		}
	}

	protected def void writeUnknownObject(Object value) {
		if (appendObjectStart(value)) {
			generator.writeFieldName(CONTENT)
			generator.writeString(value.toString())
			appendObjectEnd()
		}
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