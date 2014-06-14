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
package test.com.blockwithme.meta

import static org.junit.Assert.*

import org.junit.Test
import java.util.List
import com.blockwithme.meta.HierarchyListener
import com.blockwithme.meta.Hierarchy
import com.blockwithme.meta.Type
import com.blockwithme.meta.MetaProperty
import com.blockwithme.meta.PropertyType
import com.blockwithme.util.shared.converters.BooleanConverter
import com.blockwithme.util.shared.converters.ByteConverter
import com.blockwithme.util.shared.converters.ShortConverter
import com.blockwithme.util.shared.converters.CharConverter
import com.blockwithme.util.shared.converters.IntConverter
import com.blockwithme.util.shared.converters.LongConverter
import com.blockwithme.util.shared.converters.FloatConverter
import com.blockwithme.util.shared.converters.DoubleConverter
import com.blockwithme.meta.Kind
import com.blockwithme.util.shared.Footprint
import java.util.Map
import org.junit.BeforeClass
import com.blockwithme.meta.JavaMeta
import com.blockwithme.meta.MetaHierarchyBuilder
import com.blockwithme.meta.beans.Meta
import java.util.HashSet

class MyHierarchyListener implements HierarchyListener {
	public val List<Hierarchy> hierarchies = newArrayList()
	public val List<Type> types = newArrayList()
	public val List<MetaProperty> metaProperties = newArrayList()

	override onNewHierarchy(Hierarchy newHierarchy) {
		hierarchies.add(newHierarchy)
	}

	override onNewType(Type<?> newType) {
		types.add(newType)
	}

	override onNewMetaProperty(MetaProperty<?, ?> newMetaProp) {
		metaProperties.add(newMetaProp)
	}

}

/**
 * @author monster
 *
 */
class TypeTest {
	@BeforeClass
	public static def void classSetup() {
		// Force full init
		MetaHierarchyBuilder::init()
	}

    @Test
    public def void testHierarchyListener() {
    	val listener = new MyHierarchyListener
    	Hierarchy.addListener(listener)
    	assertTrue(listener.hierarchies.contains(JavaMeta.HIERARCHY))
    	assertTrue(listener.types.contains(JavaMeta.STRING))
    	assertTrue(listener.hierarchies.contains(TestMeta.TEST))
    	assertTrue(listener.types.contains(TestMeta.MY_TYPE))
    	assertEquals(listener.metaProperties.size, 1)
    	assertTrue(listener.metaProperties.contains(TestMeta.META_PROP))
    	// Check that things registered *after* the listener gets passed to a new listener.
    	MyLazyLoadListenerTST.TST.toString
    	assertEquals(listener.metaProperties.size, 2)
    	assertTrue(listener.metaProperties.contains(MyLazyLoadListenerTST.TST))
	}

    @Test
    public def void testPropGet() {
    	val obj = new MyType

    	assertEquals(false, TestMeta.BOOL_PROP.getBoolean(obj))
    	assertEquals(0 as byte, TestMeta.BYTE_PROP.getByte(obj))
    	assertEquals(0 as short, TestMeta.SHORT_PROP.getShort(obj))
    	assertEquals(' '.charAt(0), TestMeta.CHAR_PROP.getChar(obj))
    	assertEquals(0, TestMeta.INT_PROP.getInt(obj))
    	assertEquals(0L, TestMeta.LONG_PROP.getLong(obj))
    	assertEquals(0.0f, TestMeta.FLOAT_PROP.getFloat(obj), 0.001f)
    	assertEquals(0.0, TestMeta.DOUBLE_PROP.getDouble(obj), 0.001)
    	assertEquals("", TestMeta.OBJECT_PROP.getObject(obj))
    	assertEquals(MyEnum.A, TestMeta.ENUM_PROP.getObject(obj))
    	assertEquals(false, TestMeta.VIRTUAL_BOOL_PROP.getBoolean(obj))

    	obj.boolProp = true
    	obj.byteProp = 42 as byte
    	obj.shortProp = 42 as short
    	obj.charProp = '\u0042' // 42 Hex, not 42 decimal!
    	obj.intProp = 42
    	obj.longProp = 42L
    	obj.floatProp = 42.0f
    	obj.doubleProp = 42.0
    	obj.objectProp = "42"
    	obj.enumProp = EnumConverter.DEFAULT.fromObject(obj, MyEnum.C)

    	assertEquals(true, TestMeta.BOOL_PROP.getBoolean(obj))
    	assertEquals(42 as byte, TestMeta.BYTE_PROP.getByte(obj))
    	assertEquals(42 as short, TestMeta.SHORT_PROP.getShort(obj))
    	assertEquals('\u0042'.charAt(0), TestMeta.CHAR_PROP.getChar(obj))
    	assertEquals(42, TestMeta.INT_PROP.getInt(obj))
    	assertEquals(42L, TestMeta.LONG_PROP.getLong(obj))
    	assertEquals(42.0f, TestMeta.FLOAT_PROP.getFloat(obj), 0.001f)
    	assertEquals(42.0, TestMeta.DOUBLE_PROP.getDouble(obj), 0.001)
    	assertEquals("42", TestMeta.OBJECT_PROP.getObject(obj))
    	assertEquals(MyEnum.C, TestMeta.ENUM_PROP.getObject(obj))
    	assertEquals(true, TestMeta.VIRTUAL_BOOL_PROP.getBoolean(obj))
    }

    @Test
    public def void testPropSet() {
    	val obj = new MyType

    	assertEquals(false, obj.boolProp)
    	assertEquals(0 as byte, obj.byteProp)
    	assertEquals(0 as short, obj.shortProp)
    	assertEquals(' '.charAt(0), obj.charProp)
    	assertEquals(0, obj.intProp)
    	assertEquals(0L, obj.longProp)
    	assertEquals(0.0f, obj.floatProp, 0.001f)
    	assertEquals(0.0, obj.doubleProp, 0.001)
    	assertEquals("", obj.objectProp)
    	assertEquals(0, obj.enumProp)

    	assertEquals(obj, TestMeta.BOOL_PROP.setBoolean(obj, true))
    	assertEquals(obj, TestMeta.BYTE_PROP.setByte(obj, 42 as byte))
    	assertEquals(obj, TestMeta.SHORT_PROP.setShort(obj, 42 as short))
    	assertEquals(obj, TestMeta.CHAR_PROP.setChar(obj, '\u0042')) // 42 Hex, not 42 decimal!
    	assertEquals(obj, TestMeta.INT_PROP.setInt(obj, 42))
    	assertEquals(obj, TestMeta.LONG_PROP.setLong(obj, 42L))
    	assertEquals(obj, TestMeta.FLOAT_PROP.setFloat(obj, 42.0f))
    	assertEquals(obj, TestMeta.DOUBLE_PROP.setDouble(obj, 42.0))
    	assertEquals(obj, TestMeta.OBJECT_PROP.setObject(obj, "42"))
    	assertEquals(obj, TestMeta.ENUM_PROP.setInt(obj, EnumConverter.DEFAULT.fromObject(obj, MyEnum.C)))

    	assertEquals(true, obj.boolProp)
    	assertEquals(42 as byte, obj.byteProp)
    	assertEquals(42 as short, obj.shortProp)
    	assertEquals('\u0042'.charAt(0), obj.charProp)
    	assertEquals(42, obj.intProp)
    	assertEquals(42L, obj.longProp)
    	assertEquals(42.0f, obj.floatProp, 0.001f)
    	assertEquals(42.0, obj.doubleProp, 0.001)
    	assertEquals("42", obj.objectProp)
    	assertEquals(EnumConverter.DEFAULT.fromObject(obj, MyEnum.C), obj.enumProp)

    	assertEquals(obj, TestMeta.VIRTUAL_BOOL_PROP.setBoolean(obj, false))
    	assertEquals(false, obj.boolProp)
    }

    @Test
    public def void testPropGetObject() {
    	val obj = new MyType

    	assertEquals(Boolean.FALSE, TestMeta.BOOL_PROP.getObject(obj))
    	assertEquals(new Byte(0 as byte), TestMeta.BYTE_PROP.getObject(obj))
    	assertEquals(new Short(0 as short), TestMeta.SHORT_PROP.getObject(obj))
    	assertEquals(new Character(' '.charAt(0)), TestMeta.CHAR_PROP.getObject(obj))
    	assertEquals(new Integer(0), TestMeta.INT_PROP.getObject(obj))
    	assertEquals(new Long(0L), TestMeta.LONG_PROP.getObject(obj))
    	assertEquals(new Float(0.0f), TestMeta.FLOAT_PROP.getObject(obj))
    	assertEquals(new Double(0.0), TestMeta.DOUBLE_PROP.getObject(obj))
    	assertEquals("", TestMeta.OBJECT_PROP.getObject(obj))
    	assertEquals(MyEnum.A, TestMeta.ENUM_PROP.getObject(obj))
    	assertEquals(Boolean.FALSE, TestMeta.VIRTUAL_BOOL_PROP.getObject(obj))

    	obj.boolProp = true
    	obj.byteProp = 42 as byte
    	obj.shortProp = 42 as short
    	obj.charProp = '\u0042' // 42 Hex, not 42 decimal!
    	obj.intProp = 42
    	obj.longProp = 42L
    	obj.floatProp = 42.0f
    	obj.doubleProp = 42.0
    	obj.objectProp = "42"
    	obj.enumProp = EnumConverter.DEFAULT.fromObject(obj, MyEnum.C)

    	assertEquals(Boolean.TRUE, TestMeta.BOOL_PROP.getObject(obj))
    	assertEquals(new Byte(42 as byte), TestMeta.BYTE_PROP.getObject(obj))
    	assertEquals(new Short(42 as short), TestMeta.SHORT_PROP.getObject(obj))
    	assertEquals(new Character('\u0042'.charAt(0)), TestMeta.CHAR_PROP.getObject(obj))
    	assertEquals(new Integer(42), TestMeta.INT_PROP.getObject(obj))
    	assertEquals(new Long(42L), TestMeta.LONG_PROP.getObject(obj))
    	assertEquals(new Float(42.0f), TestMeta.FLOAT_PROP.getObject(obj))
    	assertEquals(new Double(42.0), TestMeta.DOUBLE_PROP.getObject(obj))
    	assertEquals("42", TestMeta.OBJECT_PROP.getObject(obj))
    	assertEquals(MyEnum.C, TestMeta.ENUM_PROP.getObject(obj))
    	assertEquals(Boolean.TRUE, TestMeta.VIRTUAL_BOOL_PROP.getObject(obj))
    }

    @Test
    public def void testPropSetObject() {
    	val obj = new MyType

    	assertEquals(false, obj.boolProp)
    	assertEquals(0 as byte, obj.byteProp)
    	assertEquals(0 as short, obj.shortProp)
    	assertEquals(' '.charAt(0), obj.charProp)
    	assertEquals(0, obj.intProp)
    	assertEquals(0L, obj.longProp)
    	assertEquals(0.0f, obj.floatProp, 0.001f)
    	assertEquals(0.0, obj.doubleProp, 0.001)
    	assertEquals("", obj.objectProp)
    	assertEquals(0, obj.enumProp)

    	TestMeta.BOOL_PROP.setObject(obj, true)
    	TestMeta.BYTE_PROP.setObject(obj, 42 as byte)
    	TestMeta.SHORT_PROP.setObject(obj, 42 as short)
    	TestMeta.CHAR_PROP.setObject(obj, '\u0042') // 42 Hex, not 42 decimal!
    	TestMeta.INT_PROP.setObject(obj, 42)
    	TestMeta.LONG_PROP.setObject(obj, 42L)
    	TestMeta.FLOAT_PROP.setObject(obj, 42.0f)
    	TestMeta.DOUBLE_PROP.setObject(obj, 42.0)
    	TestMeta.OBJECT_PROP.setObject(obj, "42")
    	TestMeta.ENUM_PROP.setObject(obj, MyEnum.C)

    	assertEquals(true, obj.boolProp)
    	assertEquals(42 as byte, obj.byteProp)
    	assertEquals(42 as short, obj.shortProp)
    	assertEquals('\u0042'.charAt(0), obj.charProp)
    	assertEquals(42, obj.intProp)
    	assertEquals(42L, obj.longProp)
    	assertEquals(42.0f, obj.floatProp, 0.001f)
    	assertEquals(42.0, obj.doubleProp, 0.001)
    	assertEquals("42", obj.objectProp)
    	assertEquals(EnumConverter.DEFAULT.fromObject(obj, MyEnum.C), obj.enumProp)

    	TestMeta.VIRTUAL_BOOL_PROP.setObject(obj, false)
    	assertEquals(false, obj.boolProp)
    }

    @Test
    public def void testMetaProp() {
    	// Actual value could change, depending on how often the test is run!
    	val before = TestMeta.META_PROP.getObject(TestMeta.MY_TYPE)
    	val Boolean after = !before
    	TestMeta.META_PROP.setObject(TestMeta.MY_TYPE, after)
     	assertEquals(after, TestMeta.META_PROP.getObject(TestMeta.MY_TYPE))
    	assertTrue(TestMeta.META_PROP.shared)
    	assertTrue(TestMeta.META_PROP.actualInstance)
    	assertFalse(TestMeta.META_PROP.exactType)
     	assertEquals(Boolean.FALSE, TestMeta.META_PROP.defaultValue)
     	assertEquals(0, TestMeta.META_PROP.globalPropertyId)
     	assertEquals(0, TestMeta.META_PROP.propertyId)
     	assertEquals(0, TestMeta.META_PROP.objectPropertyId)
     	assertEquals(0, TestMeta.META_PROP.longOrObjectPropertyId)
    }

    @Test
    public def void testNames() {
     	assertEquals("MyType", TestMeta.MY_TYPE.simpleName)
     	assertEquals("test.com.blockwithme.meta.MyType", TestMeta.MY_TYPE.fullName)
     	assertEquals("meta", TestMeta.MY_TYPE.pkg.simpleName)
     	assertEquals("test.com.blockwithme.meta", TestMeta.MY_TYPE.pkg.fullName)
     	assertEquals("persistent", TestMeta.META_PROP.simpleName)
     	assertEquals("com.blockwithme.meta.Type.persistent", TestMeta.META_PROP.fullName)
     	assertEquals("boolProp", TestMeta.BOOL_PROP.simpleName)
     	assertEquals("test.com.blockwithme.meta.MyType.boolProp", TestMeta.BOOL_PROP.fullName)
    }

    @Test
    public def void testMetaBaseHierarchy() {
     	assertEquals(TestMeta.TEST, TestMeta.MY_TYPE.pkg.hierarchy)
     	assertEquals(TestMeta.TEST, TestMeta.MY_TYPE.hierarchy)
     	assertEquals(TestMeta.TEST, TestMeta.BOOL_PROP.hierarchy)
     	assertEquals(com.blockwithme.meta.Meta.HIERARCHY, TestMeta.META_PROP.hierarchy)
    }

    @Test
    public def void testPropContentType() {
    	assertEquals(JavaMeta.BOOLEAN, TestMeta.BOOL_PROP.contentType)
    	assertEquals(JavaMeta.BYTE, TestMeta.BYTE_PROP.contentType)
    	assertEquals(JavaMeta.SHORT, TestMeta.SHORT_PROP.contentType)
    	assertEquals(JavaMeta.CHARACTER, TestMeta.CHAR_PROP.contentType)
    	assertEquals(JavaMeta.INTEGER, TestMeta.INT_PROP.contentType)
    	assertEquals(JavaMeta.LONG, TestMeta.LONG_PROP.contentType)
    	assertEquals(JavaMeta.FLOAT, TestMeta.FLOAT_PROP.contentType)
    	assertEquals(JavaMeta.DOUBLE, TestMeta.DOUBLE_PROP.contentType)
    	assertEquals(JavaMeta.STRING, TestMeta.OBJECT_PROP.contentType)
    	assertEquals(TestMeta.ENUM_TYPE, TestMeta.ENUM_PROP.contentType)
    	assertEquals(JavaMeta.BOOLEAN, TestMeta.VIRTUAL_BOOL_PROP.contentType)
    }

    @Test
    public def void testPropType() {
    	assertEquals(PropertyType.BOOLEAN, TestMeta.BOOL_PROP.type)
    	assertEquals(PropertyType.BYTE, TestMeta.BYTE_PROP.type)
    	assertEquals(PropertyType.SHORT, TestMeta.SHORT_PROP.type)
    	assertEquals(PropertyType.CHARACTER, TestMeta.CHAR_PROP.type)
    	assertEquals(PropertyType.INTEGER, TestMeta.INT_PROP.type)
    	assertEquals(PropertyType.LONG, TestMeta.LONG_PROP.type)
    	assertEquals(PropertyType.FLOAT, TestMeta.FLOAT_PROP.type)
    	assertEquals(PropertyType.DOUBLE, TestMeta.DOUBLE_PROP.type)
    	assertEquals(PropertyType.OBJECT, TestMeta.OBJECT_PROP.type)
    	assertEquals(PropertyType.INTEGER, TestMeta.ENUM_PROP.type)
    	assertEquals(PropertyType.BOOLEAN, TestMeta.VIRTUAL_BOOL_PROP.type)
    }

    @Test
    public def void testPropPrimitive() {
    	assertTrue(TestMeta.BOOL_PROP.primitive)
    	assertTrue(TestMeta.BYTE_PROP.primitive)
    	assertTrue(TestMeta.SHORT_PROP.primitive)
    	assertTrue(TestMeta.CHAR_PROP.primitive)
    	assertTrue(TestMeta.INT_PROP.primitive)
    	assertTrue(TestMeta.LONG_PROP.primitive)
    	assertTrue(TestMeta.FLOAT_PROP.primitive)
    	assertTrue(TestMeta.DOUBLE_PROP.primitive)
    	assertFalse(TestMeta.OBJECT_PROP.primitive)
    	assertFalse(TestMeta.ENUM_PROP.primitive)
    	assertFalse(TestMeta.META_PROP.primitive)
    	assertTrue(TestMeta.VIRTUAL_BOOL_PROP.primitive)
    }

    @Test
    public def void testPropMeta() {
    	assertFalse(TestMeta.BOOL_PROP.meta)
    	assertFalse(TestMeta.BYTE_PROP.meta)
    	assertFalse(TestMeta.SHORT_PROP.meta)
    	assertFalse(TestMeta.CHAR_PROP.meta)
    	assertFalse(TestMeta.INT_PROP.meta)
    	assertFalse(TestMeta.LONG_PROP.meta)
    	assertFalse(TestMeta.FLOAT_PROP.meta)
    	assertFalse(TestMeta.DOUBLE_PROP.meta)
    	assertFalse(TestMeta.OBJECT_PROP.meta)
    	assertTrue(TestMeta.META_PROP.meta)
    	assertFalse(TestMeta.ENUM_PROP.meta)
    	assertFalse(TestMeta.VIRTUAL_BOOL_PROP.meta)
    }

    @Test
    public def void testPrimPropFloatingPoint() {
    	assertFalse(TestMeta.BOOL_PROP.floatingPoint)
    	assertFalse(TestMeta.BYTE_PROP.floatingPoint)
    	assertFalse(TestMeta.SHORT_PROP.floatingPoint)
    	assertFalse(TestMeta.CHAR_PROP.floatingPoint)
    	assertFalse(TestMeta.INT_PROP.floatingPoint)
    	assertFalse(TestMeta.LONG_PROP.floatingPoint)
    	assertTrue(TestMeta.FLOAT_PROP.floatingPoint)
    	assertTrue(TestMeta.DOUBLE_PROP.floatingPoint)
    	assertFalse(TestMeta.ENUM_PROP.floatingPoint)
    	assertFalse(TestMeta.VIRTUAL_BOOL_PROP.floatingPoint)
    }

    @Test
    public def void testPrimPropSixtyFourBit() {
    	assertFalse(TestMeta.BOOL_PROP.sixtyFourBit)
    	assertFalse(TestMeta.BYTE_PROP.sixtyFourBit)
    	assertFalse(TestMeta.SHORT_PROP.sixtyFourBit)
    	assertFalse(TestMeta.CHAR_PROP.sixtyFourBit)
    	assertFalse(TestMeta.INT_PROP.sixtyFourBit)
    	assertTrue(TestMeta.LONG_PROP.sixtyFourBit)
    	assertFalse(TestMeta.FLOAT_PROP.sixtyFourBit)
    	assertTrue(TestMeta.DOUBLE_PROP.sixtyFourBit)
    	assertFalse(TestMeta.ENUM_PROP.sixtyFourBit)
    	assertFalse(TestMeta.VIRTUAL_BOOL_PROP.sixtyFourBit)
    }

    @Test
    public def void testPrimPropSigned() {
    	assertFalse(TestMeta.BOOL_PROP.signed)
    	assertTrue(TestMeta.BYTE_PROP.signed)
    	assertTrue(TestMeta.SHORT_PROP.signed)
    	assertFalse(TestMeta.CHAR_PROP.signed)
    	assertTrue(TestMeta.INT_PROP.signed)
    	assertTrue(TestMeta.LONG_PROP.signed)
    	assertTrue(TestMeta.FLOAT_PROP.signed)
    	assertTrue(TestMeta.DOUBLE_PROP.signed)
    	assertTrue(TestMeta.ENUM_PROP.signed)
    	assertFalse(TestMeta.VIRTUAL_BOOL_PROP.signed)
    }

    @Test
    public def void testPrimPropWrapper() {
    	assertTrue(TestMeta.BOOL_PROP.wrapper)
    	assertTrue(TestMeta.BYTE_PROP.wrapper)
    	assertTrue(TestMeta.SHORT_PROP.wrapper)
    	assertTrue(TestMeta.CHAR_PROP.wrapper)
    	assertTrue(TestMeta.INT_PROP.wrapper)
    	assertTrue(TestMeta.LONG_PROP.wrapper)
    	assertTrue(TestMeta.FLOAT_PROP.wrapper)
    	assertTrue(TestMeta.DOUBLE_PROP.wrapper)
    	assertFalse(TestMeta.ENUM_PROP.wrapper)
    	assertTrue(TestMeta.VIRTUAL_BOOL_PROP.wrapper)
    }

    @Test
    public def void testPrimPropBits() {
    	assertEquals(1, TestMeta.BOOL_PROP.bits)
    	assertEquals(8, TestMeta.BYTE_PROP.bits)
    	assertEquals(16, TestMeta.SHORT_PROP.bits)
    	assertEquals(16, TestMeta.CHAR_PROP.bits)
    	assertEquals(32, TestMeta.INT_PROP.bits)
    	assertEquals(64, TestMeta.LONG_PROP.bits)
    	assertEquals(32, TestMeta.FLOAT_PROP.bits)
    	assertEquals(64, TestMeta.DOUBLE_PROP.bits)
    	assertEquals(32, TestMeta.ENUM_PROP.bits)
    	assertEquals(1, TestMeta.VIRTUAL_BOOL_PROP.bits)
    }

    @Test
    public def void testPrimPropBytes() {
    	assertEquals(1, TestMeta.BOOL_PROP.bytes)
    	assertEquals(1, TestMeta.BYTE_PROP.bytes)
    	assertEquals(2, TestMeta.SHORT_PROP.bytes)
    	assertEquals(2, TestMeta.CHAR_PROP.bytes)
    	assertEquals(4, TestMeta.INT_PROP.bytes)
    	assertEquals(8, TestMeta.LONG_PROP.bytes)
    	assertEquals(4, TestMeta.FLOAT_PROP.bytes)
    	assertEquals(8, TestMeta.DOUBLE_PROP.bytes)
    	assertEquals(4, TestMeta.ENUM_PROP.bytes)
    	assertEquals(1, TestMeta.VIRTUAL_BOOL_PROP.bytes)
    }

    @Test
    public def void testPrimPropConverter() {
    	assertEquals(BooleanConverter.DEFAULT, TestMeta.BOOL_PROP.converter)
    	assertEquals(ByteConverter.DEFAULT, TestMeta.BYTE_PROP.converter)
    	assertEquals(ShortConverter.DEFAULT, TestMeta.SHORT_PROP.converter)
    	assertEquals(CharConverter.DEFAULT, TestMeta.CHAR_PROP.converter)
    	assertEquals(IntConverter.DEFAULT, TestMeta.INT_PROP.converter)
    	assertEquals(LongConverter.DEFAULT, TestMeta.LONG_PROP.converter)
    	assertEquals(FloatConverter.DEFAULT, TestMeta.FLOAT_PROP.converter)
    	assertEquals(DoubleConverter.DEFAULT, TestMeta.DOUBLE_PROP.converter)
    	assertEquals(EnumConverter.DEFAULT, TestMeta.ENUM_PROP.converter)
    	assertEquals(BooleanConverter.DEFAULT, TestMeta.VIRTUAL_BOOL_PROP.converter)
    }

    @Test
    public def void testPropOwner() {
    	assertEquals(TestMeta.MY_TYPE, TestMeta.BOOL_PROP.owner)
    	assertEquals(TestMeta.MY_TYPE, TestMeta.BYTE_PROP.owner)
    	assertEquals(TestMeta.MY_TYPE, TestMeta.SHORT_PROP.owner)
    	assertEquals(TestMeta.MY_TYPE, TestMeta.CHAR_PROP.owner)
    	assertEquals(TestMeta.MY_TYPE, TestMeta.INT_PROP.owner)
    	assertEquals(TestMeta.MY_TYPE, TestMeta.LONG_PROP.owner)
    	assertEquals(TestMeta.MY_TYPE, TestMeta.FLOAT_PROP.owner)
    	assertEquals(TestMeta.MY_TYPE, TestMeta.DOUBLE_PROP.owner)
    	assertEquals(com.blockwithme.meta.Meta.TYPE, TestMeta.META_PROP.owner)
    	assertEquals(TestMeta.MY_TYPE, TestMeta.ENUM_PROP.owner)
    	assertEquals(TestMeta.MY_TYPE, TestMeta.VIRTUAL_BOOL_PROP.owner)
    }

    @Test
    public def void testVirtualPropIDs() {
    	assertEquals(-1, TestMeta.BOOL_PROP.virtualPropertyId)
    	assertEquals(-1, TestMeta.BYTE_PROP.virtualPropertyId)
    	assertEquals(-1, TestMeta.SHORT_PROP.virtualPropertyId)
    	assertEquals(-1, TestMeta.CHAR_PROP.virtualPropertyId)
    	assertEquals(-1, TestMeta.INT_PROP.virtualPropertyId)
    	assertEquals(-1, TestMeta.LONG_PROP.virtualPropertyId)
    	assertEquals(-1, TestMeta.FLOAT_PROP.virtualPropertyId)
    	assertEquals(-1, TestMeta.DOUBLE_PROP.virtualPropertyId)
    	assertEquals(-1, TestMeta.ENUM_PROP.virtualPropertyId)
    	assertEquals(0, TestMeta.VIRTUAL_BOOL_PROP.virtualPropertyId)
    }

    @Test
    public def void testBoolProp() {
     	assertEquals(0, TestMeta.BOOL_PROP.globalPropertyId)
     	assertEquals(0, TestMeta.BOOL_PROP.propertyId)
     	assertEquals(0, TestMeta.BOOL_PROP.primitivePropertyId)
     	assertEquals(0, TestMeta.BOOL_PROP.booleanPropertyId)
     	assertEquals(0, TestMeta.BOOL_PROP.nonSixtyFourBitPropertyId)
     	assertEquals(-1, TestMeta.BOOL_PROP.sixtyFourBitPropertyId)
     	assertEquals(0, TestMeta.BOOL_PROP.nonLongPropertyId)
     	assertEquals(-1, TestMeta.BOOL_PROP.longOrObjectPropertyId)
    }

    @Test
    public def void testByteProp() {
     	assertEquals(1, TestMeta.BYTE_PROP.globalPropertyId)
     	assertEquals(1, TestMeta.BYTE_PROP.propertyId)
     	assertEquals(1, TestMeta.BYTE_PROP.primitivePropertyId)
     	assertEquals(0, TestMeta.BYTE_PROP.bytePropertyId)
     	assertEquals(1, TestMeta.BYTE_PROP.nonSixtyFourBitPropertyId)
     	assertEquals(-1, TestMeta.BYTE_PROP.sixtyFourBitPropertyId)
     	assertEquals(1, TestMeta.BYTE_PROP.nonLongPropertyId)
     	assertEquals(-1, TestMeta.BYTE_PROP.longOrObjectPropertyId)
    }

    @Test
    public def void testCharProp() {
     	assertEquals(2, TestMeta.CHAR_PROP.globalPropertyId)
     	assertEquals(2, TestMeta.CHAR_PROP.propertyId)
     	assertEquals(2, TestMeta.CHAR_PROP.primitivePropertyId)
     	assertEquals(0, TestMeta.CHAR_PROP.characterPropertyId)
     	assertEquals(2, TestMeta.CHAR_PROP.nonSixtyFourBitPropertyId)
     	assertEquals(-1, TestMeta.CHAR_PROP.sixtyFourBitPropertyId)
     	assertEquals(2, TestMeta.CHAR_PROP.nonLongPropertyId)
     	assertEquals(-1, TestMeta.CHAR_PROP.longOrObjectPropertyId)
    }

    @Test
    public def void testShortProp() {
     	assertEquals(3, TestMeta.SHORT_PROP.globalPropertyId)
     	assertEquals(3, TestMeta.SHORT_PROP.propertyId)
     	assertEquals(3, TestMeta.SHORT_PROP.primitivePropertyId)
     	assertEquals(0, TestMeta.SHORT_PROP.shortPropertyId)
     	assertEquals(3, TestMeta.SHORT_PROP.nonSixtyFourBitPropertyId)
     	assertEquals(-1, TestMeta.SHORT_PROP.sixtyFourBitPropertyId)
     	assertEquals(3, TestMeta.SHORT_PROP.nonLongPropertyId)
     	assertEquals(-1, TestMeta.SHORT_PROP.longOrObjectPropertyId)
    }

    @Test
    public def void testIntProp() {
     	assertEquals(4, TestMeta.INT_PROP.globalPropertyId)
     	assertEquals(4, TestMeta.INT_PROP.propertyId)
     	assertEquals(4, TestMeta.INT_PROP.primitivePropertyId)
     	assertEquals(0, TestMeta.INT_PROP.integerPropertyId)
     	assertEquals(4, TestMeta.INT_PROP.nonSixtyFourBitPropertyId)
     	assertEquals(-1, TestMeta.INT_PROP.sixtyFourBitPropertyId)
     	assertEquals(4, TestMeta.INT_PROP.nonLongPropertyId)
     	assertEquals(-1, TestMeta.INT_PROP.longOrObjectPropertyId)
    }

    @Test
    public def void testLongProp() {
     	assertEquals(5, TestMeta.LONG_PROP.globalPropertyId)
     	assertEquals(5, TestMeta.LONG_PROP.propertyId)
     	assertEquals(5, TestMeta.LONG_PROP.primitivePropertyId)
     	assertEquals(0, TestMeta.LONG_PROP.longPropertyId)
     	assertEquals(-1, TestMeta.LONG_PROP.nonSixtyFourBitPropertyId)
     	assertEquals(0, TestMeta.LONG_PROP.sixtyFourBitPropertyId)
     	assertEquals(-1, TestMeta.LONG_PROP.nonLongPropertyId)
     	assertEquals(0, TestMeta.LONG_PROP.longOrObjectPropertyId)
    }

    @Test
    public def void testFloatProp() {
     	assertEquals(6, TestMeta.FLOAT_PROP.globalPropertyId)
     	assertEquals(6, TestMeta.FLOAT_PROP.propertyId)
     	assertEquals(6, TestMeta.FLOAT_PROP.primitivePropertyId)
     	assertEquals(0, TestMeta.FLOAT_PROP.floatPropertyId)
     	assertEquals(5, TestMeta.FLOAT_PROP.nonSixtyFourBitPropertyId)
     	assertEquals(-1, TestMeta.FLOAT_PROP.sixtyFourBitPropertyId)
     	assertEquals(5, TestMeta.FLOAT_PROP.nonLongPropertyId)
     	assertEquals(-1, TestMeta.FLOAT_PROP.longOrObjectPropertyId)
    }

    @Test
    public def void testDoubleProp() {
     	assertEquals(7, TestMeta.DOUBLE_PROP.globalPropertyId)
     	assertEquals(7, TestMeta.DOUBLE_PROP.propertyId)
     	assertEquals(7, TestMeta.DOUBLE_PROP.primitivePropertyId)
     	assertEquals(0, TestMeta.DOUBLE_PROP.doublePropertyId)
     	assertEquals(-1, TestMeta.DOUBLE_PROP.nonSixtyFourBitPropertyId)
     	assertEquals(1, TestMeta.DOUBLE_PROP.sixtyFourBitPropertyId)
     	assertEquals(6, TestMeta.DOUBLE_PROP.nonLongPropertyId)
     	assertEquals(-1, TestMeta.DOUBLE_PROP.longOrObjectPropertyId)
    }

    @Test
    public def void testObjectProp() {
     	assertEquals(8, TestMeta.OBJECT_PROP.globalPropertyId)
     	assertEquals(8, TestMeta.OBJECT_PROP.propertyId)
     	assertEquals(0, TestMeta.OBJECT_PROP.objectPropertyId)
     	assertEquals(1, TestMeta.OBJECT_PROP.longOrObjectPropertyId)
    	assertTrue(TestMeta.OBJECT_PROP.shared)
    	assertTrue(TestMeta.OBJECT_PROP.actualInstance)
    	assertTrue(TestMeta.OBJECT_PROP.exactType)
    }

    @Test
    public def void testEnumProp() {
     	assertEquals(9, TestMeta.ENUM_PROP.globalPropertyId)
     	assertEquals(9, TestMeta.ENUM_PROP.propertyId)
     	assertEquals(8, TestMeta.ENUM_PROP.primitivePropertyId)
     	assertEquals(1, TestMeta.ENUM_PROP.integerPropertyId)
     	assertEquals(6, TestMeta.ENUM_PROP.nonSixtyFourBitPropertyId)
     	assertEquals(-1, TestMeta.ENUM_PROP.sixtyFourBitPropertyId)
     	assertEquals(7, TestMeta.ENUM_PROP.nonLongPropertyId)
     	assertEquals(-1, TestMeta.ENUM_PROP.longOrObjectPropertyId)
    }

    @Test
    public def void testInt2Prop() {
     	assertEquals(10, TestMeta.INT_PROP2.globalPropertyId)
     	assertEquals(0, TestMeta.INT_PROP2.propertyId)
     	assertEquals(0, TestMeta.INT_PROP2.primitivePropertyId)
     	assertEquals(0, TestMeta.INT_PROP2.integerPropertyId)
     	assertEquals(0, TestMeta.INT_PROP2.nonSixtyFourBitPropertyId)
     	assertEquals(-1, TestMeta.INT_PROP2.sixtyFourBitPropertyId)
     	assertEquals(0, TestMeta.INT_PROP2.nonLongPropertyId)
     	assertEquals(-1, TestMeta.INT_PROP2.longOrObjectPropertyId)
    }

    @Test
    public def void testVirtualBoolProp() {
     	assertEquals(11, TestMeta.VIRTUAL_BOOL_PROP.globalPropertyId)
     	assertEquals(10, TestMeta.VIRTUAL_BOOL_PROP.propertyId)
     	assertEquals(-1, TestMeta.VIRTUAL_BOOL_PROP.primitivePropertyId)
     	assertEquals(-1, TestMeta.VIRTUAL_BOOL_PROP.booleanPropertyId)
     	assertEquals(-1, TestMeta.VIRTUAL_BOOL_PROP.nonSixtyFourBitPropertyId)
     	assertEquals(-1, TestMeta.VIRTUAL_BOOL_PROP.sixtyFourBitPropertyId)
     	assertEquals(-1, TestMeta.VIRTUAL_BOOL_PROP.nonLongPropertyId)
     	assertEquals(-1, TestMeta.VIRTUAL_BOOL_PROP.longOrObjectPropertyId)
    }

    @Test
    public def void testTypePackage() {
     	assertEquals(0, TestMeta.MY_TYPE.pkg.packageId)
     	assertEquals(TestMeta.package, TestMeta.MY_TYPE.pkg.pkg)
     	assertEquals(#[TestMeta.MY_TYPE,TestMeta.ENUM_TYPE,TestMeta.MY_SUB_TYPE,TestMeta.MY_COLLECTION_TYPE].toList,
     		TestMeta.MY_TYPE.pkg.types.toList
     	)
    }

    @Test
    public def void testPropSameProperty() {
    	assertFalse(TestMeta.OBJECT_PROP.sameProperty(null))
    	assertFalse(TestMeta.OBJECT_PROP.sameProperty(TestMeta.DOUBLE_PROP))
    	assertTrue(TestMeta.OBJECT_PROP.sameProperty(TestMeta.OBJECT_PROP))
    	// TODO Test two different property instance with same name
    }

    @Test
    public def void testHierarchy() {
//     	assertEquals(MyType, TestMeta.TEST.base)
     	assertEquals(newArrayList(JavaMeta.HIERARCHY,Meta.HIERARCHY), TestMeta.TEST.dependencies.toList)
     	assertEquals(new HashSet(#[JavaMeta.HIERARCHY,com.blockwithme.meta.Meta.HIERARCHY,Meta.HIERARCHY,TestMeta.TEST]),
     			new HashSet(Hierarchy.hierarchies.toList)
     	)
    }

    @Test
    public def void testType() {
     	assertEquals(MyType, TestMeta.MY_TYPE.type)
     	assertFalse(TestMeta.MY_TYPE.primitive)
     	assertEquals(0, TestMeta.MY_TYPE.parents.length)
     	assertEquals(0, TestMeta.MY_TYPE.inheritedParents.length)
     	assertEquals(newArrayList(TestMeta.BOOL_PROP, TestMeta.BYTE_PROP,
     		TestMeta.CHAR_PROP, TestMeta.SHORT_PROP, TestMeta.INT_PROP,
     		TestMeta.LONG_PROP, TestMeta.FLOAT_PROP, TestMeta.DOUBLE_PROP,
     		TestMeta.OBJECT_PROP, TestMeta.ENUM_PROP
     	).toSet, TestMeta.MY_TYPE.properties.toSet)
     	assertEquals(newArrayList(TestMeta.OBJECT_PROP), TestMeta.MY_TYPE.objectProperties.toList)
     	assertEquals(TestMeta.MY_TYPE.objectProperties.toList,
     		TestMeta.MY_TYPE.inheritedObjectProperties.toList)
     	assertEquals(<Object>newArrayList(TestMeta.BOOL_PROP, TestMeta.BYTE_PROP,
     		TestMeta.CHAR_PROP, TestMeta.SHORT_PROP, TestMeta.INT_PROP,
     		TestMeta.LONG_PROP, TestMeta.FLOAT_PROP, TestMeta.DOUBLE_PROP,
     		TestMeta.ENUM_PROP
     	).toSet, TestMeta.MY_TYPE.primitiveProperties.toSet)
     	assertEquals(TestMeta.MY_TYPE.primitiveProperties.toList,
     		TestMeta.MY_TYPE.inheritedPrimitiveProperties.toList)
     	assertEquals(10, TestMeta.MY_TYPE.inheritedProperties.length)
     	assertEquals(newArrayList(TestMeta.VIRTUAL_BOOL_PROP
     	).toSet, TestMeta.MY_TYPE.virtualProperties.toSet)
     	assertEquals(newArrayList(TestMeta.VIRTUAL_BOOL_PROP
     	).toSet, TestMeta.MY_TYPE.inheritedVirtualProperties.toSet)
     	assertEquals(10, TestMeta.MY_TYPE.inheritedPropertyCount)
     	assertEquals(1, TestMeta.MY_TYPE.typeId)
     	assertEquals(9, TestMeta.MY_TYPE.primitivePropertyCount)
     	assertEquals(1, TestMeta.MY_TYPE.objectPropertyCount)
     	assertEquals(10, TestMeta.MY_TYPE.propertyCount)
     	assertEquals(2, TestMeta.MY_TYPE.sixtyFourBitPropertyCount)
     	assertEquals(7, TestMeta.MY_TYPE.nonSixtyFourBitPropertyCount)
     	assertEquals(1, TestMeta.MY_TYPE.booleanPrimitivePropertyCount)
     	assertEquals(1, TestMeta.MY_TYPE.bytePrimitivePropertyCount)
     	assertEquals(1, TestMeta.MY_TYPE.charPrimitivePropertyCount)
     	assertEquals(1, TestMeta.MY_TYPE.shortPrimitivePropertyCount)
     	assertEquals(2, TestMeta.MY_TYPE.intPrimitivePropertyCount)
     	assertEquals(1, TestMeta.MY_TYPE.longPrimitivePropertyCount)
     	assertEquals(1, TestMeta.MY_TYPE.floatPrimitivePropertyCount)
     	assertEquals(1, TestMeta.MY_TYPE.doublePrimitivePropertyCount)
     	assertEquals(8, TestMeta.MY_TYPE.nonLongPrimitivePropertyCount)
     	assertEquals(Kind.Implementation, TestMeta.MY_TYPE.kind)
     	assertEquals(265, TestMeta.MY_TYPE.primitivePropertyBitsTotal)
     	assertEquals(34, TestMeta.MY_TYPE.primitivePropertyByteTotal)
     	assertEquals(40, TestMeta.MY_TYPE.footprint)
     	assertEquals(40 + Footprint.OBJECT_SIZE, TestMeta.MY_TYPE.inheritedFootprint)

		val Map<String,com.blockwithme.meta.Property> map = newHashMap()
		map.putAll(TestMeta.MY_TYPE.simpleNameToProperty as Map)
		for (p : TestMeta.MY_TYPE.properties) {
			assertEquals(p, map.remove(p.simpleName))
		}
		for (p : TestMeta.MY_TYPE.virtualProperties) {
			assertEquals(p, map.remove(p.simpleName))
		}
    	assertTrue(map.empty)

    	assertFalse(TestMeta.MY_TYPE.sameType(null))
    	assertFalse(TestMeta.MY_TYPE.sameType(JavaMeta.STRING))
    	assertTrue(TestMeta.MY_TYPE.sameType(TestMeta.MY_TYPE))
    	assertTrue(TestMeta.OBJECT2.sameType(JavaMeta.OBJECT))

    	assertFalse(TestMeta.OBJECT2.isChildOf(TestMeta.MY_TYPE))
    	assertTrue(JavaMeta.STRING.isChildOf(JavaMeta.CHAR_SEQUENCE))
    	assertFalse(TestMeta.MY_TYPE.isParentOf(JavaMeta.STRING))
    	assertTrue(JavaMeta.CHAR_SEQUENCE.isParentOf(JavaMeta.STRING))
    }

    @Test
    public def void testSubType() {
     	assertEquals(MySubType, TestMeta.MY_SUB_TYPE.type)
     	assertFalse(TestMeta.MY_SUB_TYPE.primitive)
     	assertEquals(1, TestMeta.MY_SUB_TYPE.parents.length)
     	assertEquals(MyType, TestMeta.MY_SUB_TYPE.parents.get(0).type)
     	assertEquals(1, TestMeta.MY_SUB_TYPE.inheritedParents.length)
     	assertEquals(MyType, TestMeta.MY_SUB_TYPE.inheritedParents.get(0).type)
     	assertEquals(newArrayList(TestMeta.INT_PROP2).toSet,
     		TestMeta.MY_SUB_TYPE.properties.toSet)
     	assertEquals(0, TestMeta.MY_SUB_TYPE.objectProperties.length)
     	assertEquals(newArrayList(TestMeta.INT_PROP2).toSet,
     		TestMeta.MY_SUB_TYPE.primitiveProperties.toSet)
     	assertEquals(newArrayList(TestMeta.BOOL_PROP, TestMeta.BYTE_PROP,
     		TestMeta.CHAR_PROP, TestMeta.SHORT_PROP, TestMeta.INT_PROP,
     		TestMeta.LONG_PROP, TestMeta.FLOAT_PROP, TestMeta.DOUBLE_PROP,
     		TestMeta.OBJECT_PROP, TestMeta.ENUM_PROP, TestMeta.INT_PROP2
     	).toSet, TestMeta.MY_SUB_TYPE.inheritedProperties.toSet)
     	assertEquals(11, TestMeta.MY_SUB_TYPE.inheritedProperties.length)
     	assertEquals(11, TestMeta.MY_SUB_TYPE.inheritedPropertyCount)
     	assertEquals(2, TestMeta.MY_SUB_TYPE.typeId)
     	assertEquals(1, TestMeta.MY_SUB_TYPE.primitivePropertyCount)
     	assertEquals(0, TestMeta.MY_SUB_TYPE.objectPropertyCount)
     	assertEquals(1, TestMeta.MY_SUB_TYPE.propertyCount)
     	assertEquals(0, TestMeta.MY_SUB_TYPE.sixtyFourBitPropertyCount)
     	assertEquals(1, TestMeta.MY_SUB_TYPE.nonSixtyFourBitPropertyCount)
     	assertEquals(0, TestMeta.MY_SUB_TYPE.booleanPrimitivePropertyCount)
     	assertEquals(0, TestMeta.MY_SUB_TYPE.bytePrimitivePropertyCount)
     	assertEquals(0, TestMeta.MY_SUB_TYPE.charPrimitivePropertyCount)
     	assertEquals(0, TestMeta.MY_SUB_TYPE.shortPrimitivePropertyCount)
     	assertEquals(1, TestMeta.MY_SUB_TYPE.intPrimitivePropertyCount)
     	assertEquals(0, TestMeta.MY_SUB_TYPE.longPrimitivePropertyCount)
     	assertEquals(0, TestMeta.MY_SUB_TYPE.floatPrimitivePropertyCount)
     	assertEquals(0, TestMeta.MY_SUB_TYPE.doublePrimitivePropertyCount)
     	assertEquals(1, TestMeta.MY_SUB_TYPE.nonLongPrimitivePropertyCount)
     	assertEquals(Kind.Implementation, TestMeta.MY_SUB_TYPE.kind)
     	assertEquals(32, TestMeta.MY_SUB_TYPE.primitivePropertyBitsTotal)
     	assertEquals(4, TestMeta.MY_SUB_TYPE.primitivePropertyByteTotal)
     	assertEquals(8, TestMeta.MY_SUB_TYPE.footprint)
     	assertEquals(8 + TestMeta.MY_TYPE.footprint + Footprint.OBJECT_SIZE,
     		TestMeta.MY_SUB_TYPE.inheritedFootprint)

		val Map<String,com.blockwithme.meta.Property> map = newHashMap()
		map.putAll(TestMeta.MY_SUB_TYPE.simpleNameToProperty as Map)
		for (p : TestMeta.MY_SUB_TYPE.inheritedProperties) {
			assertEquals(p, map.remove(p.simpleName))
		}
		for (p : TestMeta.MY_SUB_TYPE.inheritedVirtualProperties) {
			assertEquals(p, map.remove(p.simpleName))
		}
    	assertTrue(map.empty)

    	assertFalse(TestMeta.MY_TYPE.isChildOf(TestMeta.MY_SUB_TYPE))
    	assertTrue(TestMeta.MY_SUB_TYPE.isChildOf(TestMeta.MY_TYPE))
    	assertFalse(TestMeta.MY_SUB_TYPE.isParentOf(TestMeta.MY_TYPE))
    	assertTrue(TestMeta.MY_TYPE.isParentOf(TestMeta.MY_SUB_TYPE))
    }

	// TODO Fails due to Xtend bug
//    @Test
//    public def void testCreate() {
//    	val obj = TestMeta.MY_TYPE.create
//    	assertEquals(MyType, obj.class)
//    }
}