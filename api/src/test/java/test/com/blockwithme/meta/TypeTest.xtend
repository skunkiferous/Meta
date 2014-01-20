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
import com.blockwithme.meta.Types
import com.blockwithme.meta.PropertyType
import com.blockwithme.meta.converter.BooleanConverter
import com.blockwithme.meta.converter.ByteConverter
import com.blockwithme.meta.converter.ShortConverter
import com.blockwithme.meta.converter.CharConverter
import com.blockwithme.meta.converter.IntConverter
import com.blockwithme.meta.converter.LongConverter
import com.blockwithme.meta.converter.FloatConverter
import com.blockwithme.meta.converter.DoubleConverter
import com.blockwithme.meta.Kind
import com.blockwithme.util.Footprint
import java.util.Map
import org.junit.BeforeClass

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
		Types::init()
	}

    @Test
    public def void testHierarchyListener() {
    	val listener = new MyHierarchyListener
    	Hierarchy.addListener(listener)
    	assertTrue(listener.hierarchies.contains(Types.JAVA))
    	assertTrue(listener.types.contains(Types.STRING))
    	assertTrue(listener.hierarchies.contains(MyHierarchy.TEST))
    	assertTrue(listener.types.contains(MyHierarchy.MY_TYPE))
    	assertEquals(listener.metaProperties.size, 1)
    	assertTrue(listener.metaProperties.contains(MyHierarchy.META_PROP))
    	// Check that things registered *after* the listener gets passed to a new listener.
    	MyLazyLoadListenerTST.TST.toString
    	assertEquals(listener.metaProperties.size, 2)
    	assertTrue(listener.metaProperties.contains(MyLazyLoadListenerTST.TST))
	}

    @Test
    public def void testPropGet() {
    	val obj = new MyType

    	assertEquals(false, MyType.BOOL_PROP.getBoolean(obj))
    	assertEquals(0 as byte, MyType.BYTE_PROP.getByte(obj))
    	assertEquals(0 as short, MyType.SHORT_PROP.getShort(obj))
    	assertEquals(' '.charAt(0), MyType.CHAR_PROP.getChar(obj))
    	assertEquals(0, MyType.INT_PROP.getInt(obj))
    	assertEquals(0L, MyType.LONG_PROP.getLong(obj))
    	assertEquals(0.0f, MyType.FLOAT_PROP.getFloat(obj), 0.001f)
    	assertEquals(0.0, MyType.DOUBLE_PROP.getDouble(obj), 0.001)
    	assertEquals("", MyType.OBJECT_PROP.getObject(obj))
    	assertEquals(MyEnum.A, MyType.ENUM_PROP.getObject(obj))

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

    	assertEquals(true, MyType.BOOL_PROP.getBoolean(obj))
    	assertEquals(42 as byte, MyType.BYTE_PROP.getByte(obj))
    	assertEquals(42 as short, MyType.SHORT_PROP.getShort(obj))
    	assertEquals('\u0042'.charAt(0), MyType.CHAR_PROP.getChar(obj))
    	assertEquals(42, MyType.INT_PROP.getInt(obj))
    	assertEquals(42L, MyType.LONG_PROP.getLong(obj))
    	assertEquals(42.0f, MyType.FLOAT_PROP.getFloat(obj), 0.001f)
    	assertEquals(42.0, MyType.DOUBLE_PROP.getDouble(obj), 0.001)
    	assertEquals("42", MyType.OBJECT_PROP.getObject(obj))
    	assertEquals(MyEnum.C, MyType.ENUM_PROP.getObject(obj))
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

    	assertEquals(obj, MyType.BOOL_PROP.setBoolean(obj, true))
    	assertEquals(obj, MyType.BYTE_PROP.setByte(obj, 42 as byte))
    	assertEquals(obj, MyType.SHORT_PROP.setShort(obj, 42 as short))
    	assertEquals(obj, MyType.CHAR_PROP.setChar(obj, '\u0042')) // 42 Hex, not 42 decimal!
    	assertEquals(obj, MyType.INT_PROP.setInt(obj, 42))
    	assertEquals(obj, MyType.LONG_PROP.setLong(obj, 42L))
    	assertEquals(obj, MyType.FLOAT_PROP.setFloat(obj, 42.0f))
    	assertEquals(obj, MyType.DOUBLE_PROP.setDouble(obj, 42.0))
    	assertEquals(obj, MyType.OBJECT_PROP.setObject(obj, "42"))
    	assertEquals(obj, MyType.ENUM_PROP.setInt(obj, EnumConverter.DEFAULT.fromObject(obj, MyEnum.C)))

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
    }

    @Test
    public def void testPropGetObject() {
    	val obj = new MyType

    	assertEquals(Boolean.FALSE, MyType.BOOL_PROP.getObject(obj))
    	assertEquals(new Byte(0 as byte), MyType.BYTE_PROP.getObject(obj))
    	assertEquals(new Short(0 as short), MyType.SHORT_PROP.getObject(obj))
    	assertEquals(new Character(' '.charAt(0)), MyType.CHAR_PROP.getObject(obj))
    	assertEquals(new Integer(0), MyType.INT_PROP.getObject(obj))
    	assertEquals(new Long(0L), MyType.LONG_PROP.getObject(obj))
    	assertEquals(new Float(0.0f), MyType.FLOAT_PROP.getObject(obj))
    	assertEquals(new Double(0.0), MyType.DOUBLE_PROP.getObject(obj))
    	assertEquals("", MyType.OBJECT_PROP.getObject(obj))
    	assertEquals(MyEnum.A, MyType.ENUM_PROP.getObject(obj))

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

    	assertEquals(Boolean.TRUE, MyType.BOOL_PROP.getObject(obj))
    	assertEquals(new Byte(42 as byte), MyType.BYTE_PROP.getObject(obj))
    	assertEquals(new Short(42 as short), MyType.SHORT_PROP.getObject(obj))
    	assertEquals(new Character('\u0042'.charAt(0)), MyType.CHAR_PROP.getObject(obj))
    	assertEquals(new Integer(42), MyType.INT_PROP.getObject(obj))
    	assertEquals(new Long(42L), MyType.LONG_PROP.getObject(obj))
    	assertEquals(new Float(42.0f), MyType.FLOAT_PROP.getObject(obj))
    	assertEquals(new Double(42.0), MyType.DOUBLE_PROP.getObject(obj))
    	assertEquals("42", MyType.OBJECT_PROP.getObject(obj))
    	assertEquals(MyEnum.C, MyType.ENUM_PROP.getObject(obj))
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

    	MyType.BOOL_PROP.setObject(obj, true)
    	MyType.BYTE_PROP.setObject(obj, 42 as byte)
    	MyType.SHORT_PROP.setObject(obj, 42 as short)
    	MyType.CHAR_PROP.setObject(obj, '\u0042') // 42 Hex, not 42 decimal!
    	MyType.INT_PROP.setObject(obj, 42)
    	MyType.LONG_PROP.setObject(obj, 42L)
    	MyType.FLOAT_PROP.setObject(obj, 42.0f)
    	MyType.DOUBLE_PROP.setObject(obj, 42.0)
    	MyType.OBJECT_PROP.setObject(obj, "42")
    	MyType.ENUM_PROP.setObject(obj, MyEnum.C)

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
    }

    @Test
    public def void testMetaProp() {
    	// Actual value could change, depending on how often the test is run!
    	val before = MyHierarchy.META_PROP.getObject(MyHierarchy.MY_TYPE)
    	val Boolean after = !before
    	MyHierarchy.META_PROP.setObject(MyHierarchy.MY_TYPE, after)
     	assertEquals(after, MyHierarchy.META_PROP.getObject(MyHierarchy.MY_TYPE))
    	assertTrue(MyHierarchy.META_PROP.shared)
    	assertTrue(MyHierarchy.META_PROP.actualInstance)
    	assertFalse(MyHierarchy.META_PROP.exactType)
     	assertEquals(Boolean.FALSE, MyHierarchy.META_PROP.defaultValue)
     	assertEquals(0, MyHierarchy.META_PROP.globalPropertyId)
     	assertEquals(0, MyHierarchy.META_PROP.propertyId)
     	assertEquals(0, MyHierarchy.META_PROP.objectPropertyId)
     	assertEquals(0, MyHierarchy.META_PROP.longOrObjectPropertyId)
    }

    @Test
    public def void testNames() {
     	assertEquals("MyType", MyHierarchy.MY_TYPE.simpleName)
     	assertEquals("test.com.blockwithme.meta.MyType", MyHierarchy.MY_TYPE.fullName)
     	assertEquals("meta", MyHierarchy.MY_TYPE.pkg.simpleName)
     	assertEquals("test.com.blockwithme.meta", MyHierarchy.MY_TYPE.pkg.fullName)
     	assertEquals("persistent", MyHierarchy.META_PROP.simpleName)
     	assertEquals("com.blockwithme.meta.Type.persistent", MyHierarchy.META_PROP.fullName)
     	assertEquals("boolProp", MyType.BOOL_PROP.simpleName)
     	assertEquals("test.com.blockwithme.meta.MyType.boolProp", MyType.BOOL_PROP.fullName)
    }

    @Test
    public def void testMetaBaseHierarchy() {
     	assertEquals(MyHierarchy.TEST, MyHierarchy.MY_TYPE.hierarchy)
     	assertEquals(MyHierarchy.TEST, MyHierarchy.MY_TYPE.pkg.hierarchy)
     	assertEquals(Types.META, MyHierarchy.META_PROP.hierarchy)
     	assertEquals(MyHierarchy.TEST, MyType.BOOL_PROP.hierarchy)
    }

    @Test
    public def void testPropContentType() {
    	assertEquals(Types.BOOLEAN, MyType.BOOL_PROP.contentType)
    	assertEquals(Types.BYTE, MyType.BYTE_PROP.contentType)
    	assertEquals(Types.SHORT, MyType.SHORT_PROP.contentType)
    	assertEquals(Types.CHARACTER, MyType.CHAR_PROP.contentType)
    	assertEquals(Types.INTEGER, MyType.INT_PROP.contentType)
    	assertEquals(Types.LONG, MyType.LONG_PROP.contentType)
    	assertEquals(Types.FLOAT, MyType.FLOAT_PROP.contentType)
    	assertEquals(Types.DOUBLE, MyType.DOUBLE_PROP.contentType)
    	assertEquals(Types.STRING, MyType.OBJECT_PROP.contentType)
    	assertEquals(MyHierarchyBuilder.ENUM_TYPE, MyType.ENUM_PROP.contentType)
    }

    @Test
    public def void testPropType() {
    	assertEquals(PropertyType.BOOLEAN, MyType.BOOL_PROP.type)
    	assertEquals(PropertyType.BYTE, MyType.BYTE_PROP.type)
    	assertEquals(PropertyType.SHORT, MyType.SHORT_PROP.type)
    	assertEquals(PropertyType.CHARACTER, MyType.CHAR_PROP.type)
    	assertEquals(PropertyType.INTEGER, MyType.INT_PROP.type)
    	assertEquals(PropertyType.LONG, MyType.LONG_PROP.type)
    	assertEquals(PropertyType.FLOAT, MyType.FLOAT_PROP.type)
    	assertEquals(PropertyType.DOUBLE, MyType.DOUBLE_PROP.type)
    	assertEquals(PropertyType.OBJECT, MyType.OBJECT_PROP.type)
    	assertEquals(PropertyType.INTEGER, MyType.ENUM_PROP.type)
    }

    @Test
    public def void testPropPrimitive() {
    	assertTrue(MyType.BOOL_PROP.primitive)
    	assertTrue(MyType.BYTE_PROP.primitive)
    	assertTrue(MyType.SHORT_PROP.primitive)
    	assertTrue(MyType.CHAR_PROP.primitive)
    	assertTrue(MyType.INT_PROP.primitive)
    	assertTrue(MyType.LONG_PROP.primitive)
    	assertTrue(MyType.FLOAT_PROP.primitive)
    	assertTrue(MyType.DOUBLE_PROP.primitive)
    	assertFalse(MyType.OBJECT_PROP.primitive)
    	assertFalse(MyType.ENUM_PROP.primitive)
    	assertFalse(MyHierarchy.META_PROP.primitive)
    }

    @Test
    public def void testPropMeta() {
    	assertFalse(MyType.BOOL_PROP.meta)
    	assertFalse(MyType.BYTE_PROP.meta)
    	assertFalse(MyType.SHORT_PROP.meta)
    	assertFalse(MyType.CHAR_PROP.meta)
    	assertFalse(MyType.INT_PROP.meta)
    	assertFalse(MyType.LONG_PROP.meta)
    	assertFalse(MyType.FLOAT_PROP.meta)
    	assertFalse(MyType.DOUBLE_PROP.meta)
    	assertFalse(MyType.OBJECT_PROP.meta)
    	assertTrue(MyHierarchy.META_PROP.meta)
    	assertFalse(MyType.ENUM_PROP.meta)
    }

    @Test
    public def void testPrimPropFloatingPoint() {
    	assertFalse(MyType.BOOL_PROP.floatingPoint)
    	assertFalse(MyType.BYTE_PROP.floatingPoint)
    	assertFalse(MyType.SHORT_PROP.floatingPoint)
    	assertFalse(MyType.CHAR_PROP.floatingPoint)
    	assertFalse(MyType.INT_PROP.floatingPoint)
    	assertFalse(MyType.LONG_PROP.floatingPoint)
    	assertTrue(MyType.FLOAT_PROP.floatingPoint)
    	assertTrue(MyType.DOUBLE_PROP.floatingPoint)
    	assertFalse(MyType.ENUM_PROP.floatingPoint)
    }

    @Test
    public def void testPrimPropSixtyFourBit() {
    	assertFalse(MyType.BOOL_PROP.sixtyFourBit)
    	assertFalse(MyType.BYTE_PROP.sixtyFourBit)
    	assertFalse(MyType.SHORT_PROP.sixtyFourBit)
    	assertFalse(MyType.CHAR_PROP.sixtyFourBit)
    	assertFalse(MyType.INT_PROP.sixtyFourBit)
    	assertTrue(MyType.LONG_PROP.sixtyFourBit)
    	assertFalse(MyType.FLOAT_PROP.sixtyFourBit)
    	assertTrue(MyType.DOUBLE_PROP.sixtyFourBit)
    	assertFalse(MyType.ENUM_PROP.sixtyFourBit)
    }

    @Test
    public def void testPrimPropSigned() {
    	assertFalse(MyType.BOOL_PROP.signed)
    	assertTrue(MyType.BYTE_PROP.signed)
    	assertTrue(MyType.SHORT_PROP.signed)
    	assertFalse(MyType.CHAR_PROP.signed)
    	assertTrue(MyType.INT_PROP.signed)
    	assertTrue(MyType.LONG_PROP.signed)
    	assertTrue(MyType.FLOAT_PROP.signed)
    	assertTrue(MyType.DOUBLE_PROP.signed)
    	assertTrue(MyType.ENUM_PROP.signed)
    }

    @Test
    public def void testPrimPropWrapper() {
    	assertTrue(MyType.BOOL_PROP.wrapper)
    	assertTrue(MyType.BYTE_PROP.wrapper)
    	assertTrue(MyType.SHORT_PROP.wrapper)
    	assertTrue(MyType.CHAR_PROP.wrapper)
    	assertTrue(MyType.INT_PROP.wrapper)
    	assertTrue(MyType.LONG_PROP.wrapper)
    	assertTrue(MyType.FLOAT_PROP.wrapper)
    	assertTrue(MyType.DOUBLE_PROP.wrapper)
    	assertFalse(MyType.ENUM_PROP.wrapper)
    }

    @Test
    public def void testPrimPropBits() {
    	assertEquals(1, MyType.BOOL_PROP.bits)
    	assertEquals(8, MyType.BYTE_PROP.bits)
    	assertEquals(16, MyType.SHORT_PROP.bits)
    	assertEquals(16, MyType.CHAR_PROP.bits)
    	assertEquals(32, MyType.INT_PROP.bits)
    	assertEquals(64, MyType.LONG_PROP.bits)
    	assertEquals(32, MyType.FLOAT_PROP.bits)
    	assertEquals(64, MyType.DOUBLE_PROP.bits)
    	assertEquals(32, MyType.ENUM_PROP.bits)
    }

    @Test
    public def void testPrimPropBytes() {
    	assertEquals(1, MyType.BOOL_PROP.bytes)
    	assertEquals(1, MyType.BYTE_PROP.bytes)
    	assertEquals(2, MyType.SHORT_PROP.bytes)
    	assertEquals(2, MyType.CHAR_PROP.bytes)
    	assertEquals(4, MyType.INT_PROP.bytes)
    	assertEquals(8, MyType.LONG_PROP.bytes)
    	assertEquals(4, MyType.FLOAT_PROP.bytes)
    	assertEquals(8, MyType.DOUBLE_PROP.bytes)
    	assertEquals(4, MyType.ENUM_PROP.bytes)
    }

    @Test
    public def void testPrimPropConverter() {
    	assertEquals(BooleanConverter.DEFAULT, MyType.BOOL_PROP.converter)
    	assertEquals(ByteConverter.DEFAULT, MyType.BYTE_PROP.converter)
    	assertEquals(ShortConverter.DEFAULT, MyType.SHORT_PROP.converter)
    	assertEquals(CharConverter.DEFAULT, MyType.CHAR_PROP.converter)
    	assertEquals(IntConverter.DEFAULT, MyType.INT_PROP.converter)
    	assertEquals(LongConverter.DEFAULT, MyType.LONG_PROP.converter)
    	assertEquals(FloatConverter.DEFAULT, MyType.FLOAT_PROP.converter)
    	assertEquals(DoubleConverter.DEFAULT, MyType.DOUBLE_PROP.converter)
    	assertEquals(EnumConverter.DEFAULT, MyType.ENUM_PROP.converter)
    }

    @Test
    public def void testPropOwner() {
    	assertEquals(MyHierarchy.MY_TYPE, MyType.BOOL_PROP.owner)
    	assertEquals(MyHierarchy.MY_TYPE, MyType.BYTE_PROP.owner)
    	assertEquals(MyHierarchy.MY_TYPE, MyType.SHORT_PROP.owner)
    	assertEquals(MyHierarchy.MY_TYPE, MyType.CHAR_PROP.owner)
    	assertEquals(MyHierarchy.MY_TYPE, MyType.INT_PROP.owner)
    	assertEquals(MyHierarchy.MY_TYPE, MyType.LONG_PROP.owner)
    	assertEquals(MyHierarchy.MY_TYPE, MyType.FLOAT_PROP.owner)
    	assertEquals(MyHierarchy.MY_TYPE, MyType.DOUBLE_PROP.owner)
    	assertEquals(Types.TYPE, MyHierarchy.META_PROP.owner)
    	assertEquals(MyHierarchy.MY_TYPE, MyType.ENUM_PROP.owner)
    }

    @Test
    public def void testBoolProp() {
     	assertEquals(0, MyType.BOOL_PROP.globalPropertyId)
     	assertEquals(0, MyType.BOOL_PROP.propertyId)
     	assertEquals(0, MyType.BOOL_PROP.primitivePropertyId)
     	assertEquals(0, MyType.BOOL_PROP.booleanPropertyId)
     	assertEquals(0, MyType.BOOL_PROP.nonSixtyFourBitPropertyId)
     	assertEquals(-1, MyType.BOOL_PROP.sixtyFourBitPropertyId)
     	assertEquals(0, MyType.BOOL_PROP.nonLongPropertyId)
     	assertEquals(-1, MyType.BOOL_PROP.longOrObjectPropertyId)
    }

    @Test
    public def void testByteProp() {
     	assertEquals(1, MyType.BYTE_PROP.globalPropertyId)
     	assertEquals(1, MyType.BYTE_PROP.propertyId)
     	assertEquals(1, MyType.BYTE_PROP.primitivePropertyId)
     	assertEquals(0, MyType.BYTE_PROP.bytePropertyId)
     	assertEquals(1, MyType.BYTE_PROP.nonSixtyFourBitPropertyId)
     	assertEquals(-1, MyType.BYTE_PROP.sixtyFourBitPropertyId)
     	assertEquals(1, MyType.BYTE_PROP.nonLongPropertyId)
     	assertEquals(-1, MyType.BYTE_PROP.longOrObjectPropertyId)
    }

    @Test
    public def void testCharProp() {
     	assertEquals(2, MyType.CHAR_PROP.globalPropertyId)
     	assertEquals(2, MyType.CHAR_PROP.propertyId)
     	assertEquals(2, MyType.CHAR_PROP.primitivePropertyId)
     	assertEquals(0, MyType.CHAR_PROP.characterPropertyId)
     	assertEquals(2, MyType.CHAR_PROP.nonSixtyFourBitPropertyId)
     	assertEquals(-1, MyType.CHAR_PROP.sixtyFourBitPropertyId)
     	assertEquals(2, MyType.CHAR_PROP.nonLongPropertyId)
     	assertEquals(-1, MyType.CHAR_PROP.longOrObjectPropertyId)
    }

    @Test
    public def void testShortProp() {
     	assertEquals(3, MyType.SHORT_PROP.globalPropertyId)
     	assertEquals(3, MyType.SHORT_PROP.propertyId)
     	assertEquals(3, MyType.SHORT_PROP.primitivePropertyId)
     	assertEquals(0, MyType.SHORT_PROP.shortPropertyId)
     	assertEquals(3, MyType.SHORT_PROP.nonSixtyFourBitPropertyId)
     	assertEquals(-1, MyType.SHORT_PROP.sixtyFourBitPropertyId)
     	assertEquals(3, MyType.SHORT_PROP.nonLongPropertyId)
     	assertEquals(-1, MyType.SHORT_PROP.longOrObjectPropertyId)
    }

    @Test
    public def void testIntProp() {
     	assertEquals(4, MyType.INT_PROP.globalPropertyId)
     	assertEquals(4, MyType.INT_PROP.propertyId)
     	assertEquals(4, MyType.INT_PROP.primitivePropertyId)
     	assertEquals(0, MyType.INT_PROP.integerPropertyId)
     	assertEquals(4, MyType.INT_PROP.nonSixtyFourBitPropertyId)
     	assertEquals(-1, MyType.INT_PROP.sixtyFourBitPropertyId)
     	assertEquals(4, MyType.INT_PROP.nonLongPropertyId)
     	assertEquals(-1, MyType.INT_PROP.longOrObjectPropertyId)
    }

    @Test
    public def void testLongProp() {
     	assertEquals(5, MyType.LONG_PROP.globalPropertyId)
     	assertEquals(5, MyType.LONG_PROP.propertyId)
     	assertEquals(5, MyType.LONG_PROP.primitivePropertyId)
     	assertEquals(0, MyType.LONG_PROP.longPropertyId)
     	assertEquals(-1, MyType.LONG_PROP.nonSixtyFourBitPropertyId)
     	assertEquals(0, MyType.LONG_PROP.sixtyFourBitPropertyId)
     	assertEquals(-1, MyType.LONG_PROP.nonLongPropertyId)
     	assertEquals(0, MyType.LONG_PROP.longOrObjectPropertyId)
    }

    @Test
    public def void testFloatProp() {
     	assertEquals(6, MyType.FLOAT_PROP.globalPropertyId)
     	assertEquals(6, MyType.FLOAT_PROP.propertyId)
     	assertEquals(6, MyType.FLOAT_PROP.primitivePropertyId)
     	assertEquals(0, MyType.FLOAT_PROP.floatPropertyId)
     	assertEquals(5, MyType.FLOAT_PROP.nonSixtyFourBitPropertyId)
     	assertEquals(-1, MyType.FLOAT_PROP.sixtyFourBitPropertyId)
     	assertEquals(5, MyType.FLOAT_PROP.nonLongPropertyId)
     	assertEquals(-1, MyType.FLOAT_PROP.longOrObjectPropertyId)
    }

    @Test
    public def void testDoubleProp() {
     	assertEquals(7, MyType.DOUBLE_PROP.globalPropertyId)
     	assertEquals(7, MyType.DOUBLE_PROP.propertyId)
     	assertEquals(7, MyType.DOUBLE_PROP.primitivePropertyId)
     	assertEquals(0, MyType.DOUBLE_PROP.doublePropertyId)
     	assertEquals(-1, MyType.DOUBLE_PROP.nonSixtyFourBitPropertyId)
     	assertEquals(1, MyType.DOUBLE_PROP.sixtyFourBitPropertyId)
     	assertEquals(6, MyType.DOUBLE_PROP.nonLongPropertyId)
     	assertEquals(-1, MyType.DOUBLE_PROP.longOrObjectPropertyId)
    }

    @Test
    public def void testObjectProp() {
     	assertEquals(8, MyType.OBJECT_PROP.globalPropertyId)
     	assertEquals(8, MyType.OBJECT_PROP.propertyId)
     	assertEquals(0, MyType.OBJECT_PROP.objectPropertyId)
     	assertEquals(1, MyType.OBJECT_PROP.longOrObjectPropertyId)
    	assertTrue(MyType.OBJECT_PROP.shared)
    	assertTrue(MyType.OBJECT_PROP.actualInstance)
    	assertTrue(MyType.OBJECT_PROP.exactType)
    }

    @Test
    public def void testEnumProp() {
     	assertEquals(9, MyType.ENUM_PROP.globalPropertyId)
     	assertEquals(9, MyType.ENUM_PROP.propertyId)
     	assertEquals(8, MyType.ENUM_PROP.primitivePropertyId)
     	assertEquals(1, MyType.ENUM_PROP.integerPropertyId)
     	assertEquals(6, MyType.ENUM_PROP.nonSixtyFourBitPropertyId)
     	assertEquals(-1, MyType.ENUM_PROP.sixtyFourBitPropertyId)
     	assertEquals(7, MyType.ENUM_PROP.nonLongPropertyId)
     	assertEquals(-1, MyType.ENUM_PROP.longOrObjectPropertyId)
    }

    @Test
    public def void testTypePackage() {
     	assertEquals(0, MyHierarchy.MY_TYPE.pkg.packageId)
     	assertEquals(MyType.package, MyHierarchy.MY_TYPE.pkg.pkg)
     	assertEquals(#[MyHierarchy.MY_TYPE,MyHierarchyBuilder.ENUM_TYPE,MyHierarchy.MY_SUB_TYPE].toList,
     		MyHierarchy.MY_TYPE.pkg.types.toList
     	)
    }

    @Test
    public def void testPropSameProperty() {
    	assertFalse(MyType.OBJECT_PROP.sameProperty(null))
    	assertFalse(MyType.OBJECT_PROP.sameProperty(MyType.DOUBLE_PROP))
    	assertTrue(MyType.OBJECT_PROP.sameProperty(MyType.OBJECT_PROP))
    	// TODO Test two different property instance with same name
    }

    @Test
    public def void testHierarchy() {
//     	assertEquals(MyType, MyHierarchy.TEST.base)
     	assertEquals(newArrayList(Types.JAVA), MyHierarchy.TEST.dependencies.toList)
     	assertEquals(newArrayList(Types.JAVA,Types.META,MyHierarchy.TEST), Hierarchy.hierarchies.toList)
    }

    @Test
    public def void testType() {
     	assertEquals(MyType, MyHierarchy.MY_TYPE.type)
     	assertFalse(MyHierarchy.MY_TYPE.primitive)
     	assertEquals(0, MyHierarchy.MY_TYPE.parents.length)
     	assertEquals(0, MyHierarchy.MY_TYPE.inheritedParents.length)
     	assertEquals(newArrayList(MyType.BOOL_PROP, MyType.BYTE_PROP,
     		MyType.CHAR_PROP, MyType.SHORT_PROP, MyType.INT_PROP,
     		MyType.LONG_PROP, MyType.FLOAT_PROP, MyType.DOUBLE_PROP,
     		MyType.OBJECT_PROP, MyType.ENUM_PROP
     	).toSet, MyHierarchy.MY_TYPE.properties.toSet)
     	assertEquals(newArrayList(MyType.OBJECT_PROP), MyHierarchy.MY_TYPE.objectProperties.toList)
     	assertEquals(newArrayList(MyType.BOOL_PROP, MyType.BYTE_PROP,
     		MyType.CHAR_PROP, MyType.SHORT_PROP, MyType.INT_PROP,
     		MyType.LONG_PROP, MyType.FLOAT_PROP, MyType.DOUBLE_PROP,
     		MyType.ENUM_PROP
     	).toSet, MyHierarchy.MY_TYPE.primitiveProperties.toSet)
     	assertEquals(10, MyHierarchy.MY_TYPE.inheritedProperties.length)
     	assertEquals(1, MyHierarchy.MY_TYPE.typeId)
     	assertEquals(9, MyHierarchy.MY_TYPE.primitivePropertyCount)
     	assertEquals(1, MyHierarchy.MY_TYPE.objectPropertyCount)
     	assertEquals(10, MyHierarchy.MY_TYPE.propertyCount)
     	assertEquals(2, MyHierarchy.MY_TYPE.sixtyFourBitPropertyCount)
     	assertEquals(7, MyHierarchy.MY_TYPE.nonSixtyFourBitPropertyCount)
     	assertEquals(1, MyHierarchy.MY_TYPE.booleanPrimitivePropertyCount)
     	assertEquals(1, MyHierarchy.MY_TYPE.bytePrimitivePropertyCount)
     	assertEquals(1, MyHierarchy.MY_TYPE.charPrimitivePropertyCount)
     	assertEquals(1, MyHierarchy.MY_TYPE.shortPrimitivePropertyCount)
     	assertEquals(2, MyHierarchy.MY_TYPE.intPrimitivePropertyCount)
     	assertEquals(1, MyHierarchy.MY_TYPE.longPrimitivePropertyCount)
     	assertEquals(1, MyHierarchy.MY_TYPE.floatPrimitivePropertyCount)
     	assertEquals(1, MyHierarchy.MY_TYPE.doublePrimitivePropertyCount)
     	assertEquals(8, MyHierarchy.MY_TYPE.nonLongPrimitivePropertyCount)
     	assertEquals(Kind.Implementation, MyHierarchy.MY_TYPE.kind)
     	assertEquals(265, MyHierarchy.MY_TYPE.primitivePropertyBitsTotal)
     	assertEquals(34, MyHierarchy.MY_TYPE.primitivePropertyByteTotal)
     	assertEquals(40, MyHierarchy.MY_TYPE.footprint)
     	assertEquals(40 + Footprint.OBJECT_SIZE, MyHierarchy.MY_TYPE.inheritedFootprint)

		val Map<String,com.blockwithme.meta.Property> map = newHashMap()
		map.putAll(MyHierarchy.MY_TYPE.simpleNameToProperty as Map)
		for (p : MyHierarchy.MY_TYPE.properties) {
			assertEquals(p, map.remove(p.simpleName))
		}
    	assertTrue(map.empty)

    	assertFalse(MyHierarchy.MY_TYPE.sameType(null))
    	assertFalse(MyHierarchy.MY_TYPE.sameType(Types.STRING))
    	assertTrue(MyHierarchy.MY_TYPE.sameType(MyHierarchy.MY_TYPE))
    	assertTrue(MyHierarchy.OBJECT2.sameType(Types.OBJECT))

    	assertFalse(MyHierarchy.OBJECT2.isChildOf(MyHierarchy.MY_TYPE))
    	assertTrue(Types.STRING.isChildOf(Types.CHAR_SEQUENCE))
    	assertFalse(MyHierarchy.MY_TYPE.isParentOf(Types.STRING))
    	assertTrue(Types.CHAR_SEQUENCE.isParentOf(Types.STRING))
    }

    @Test
    public def void testSubType() {
     	assertEquals(MySubType, MyHierarchy.MY_SUB_TYPE.type)
     	assertFalse(MyHierarchy.MY_SUB_TYPE.primitive)
     	assertEquals(1, MyHierarchy.MY_SUB_TYPE.parents.length)
     	assertEquals(MyType, MyHierarchy.MY_SUB_TYPE.parents.get(0).type)
     	assertEquals(1, MyHierarchy.MY_SUB_TYPE.inheritedParents.length)
     	assertEquals(MyType, MyHierarchy.MY_SUB_TYPE.inheritedParents.get(0).type)
     	assertEquals(newArrayList(MySubType.INT_PROP2).toSet,
     		MyHierarchy.MY_SUB_TYPE.properties.toSet)
     	assertEquals(0, MyHierarchy.MY_SUB_TYPE.objectProperties.length)
     	assertEquals(newArrayList(MySubType.INT_PROP2).toSet,
     		MyHierarchy.MY_SUB_TYPE.primitiveProperties.toSet)
     	assertEquals(newArrayList(MyType.BOOL_PROP, MyType.BYTE_PROP,
     		MyType.CHAR_PROP, MyType.SHORT_PROP, MyType.INT_PROP,
     		MyType.LONG_PROP, MyType.FLOAT_PROP, MyType.DOUBLE_PROP,
     		MyType.OBJECT_PROP, MyType.ENUM_PROP, MySubType.INT_PROP2
     	).toSet, MyHierarchy.MY_SUB_TYPE.inheritedProperties.toSet)
     	assertEquals(11, MyHierarchy.MY_SUB_TYPE.inheritedProperties.length)
     	assertEquals(2, MyHierarchy.MY_SUB_TYPE.typeId)
     	assertEquals(1, MyHierarchy.MY_SUB_TYPE.primitivePropertyCount)
     	assertEquals(0, MyHierarchy.MY_SUB_TYPE.objectPropertyCount)
     	assertEquals(1, MyHierarchy.MY_SUB_TYPE.propertyCount)
     	assertEquals(0, MyHierarchy.MY_SUB_TYPE.sixtyFourBitPropertyCount)
     	assertEquals(1, MyHierarchy.MY_SUB_TYPE.nonSixtyFourBitPropertyCount)
     	assertEquals(0, MyHierarchy.MY_SUB_TYPE.booleanPrimitivePropertyCount)
     	assertEquals(0, MyHierarchy.MY_SUB_TYPE.bytePrimitivePropertyCount)
     	assertEquals(0, MyHierarchy.MY_SUB_TYPE.charPrimitivePropertyCount)
     	assertEquals(0, MyHierarchy.MY_SUB_TYPE.shortPrimitivePropertyCount)
     	assertEquals(1, MyHierarchy.MY_SUB_TYPE.intPrimitivePropertyCount)
     	assertEquals(0, MyHierarchy.MY_SUB_TYPE.longPrimitivePropertyCount)
     	assertEquals(0, MyHierarchy.MY_SUB_TYPE.floatPrimitivePropertyCount)
     	assertEquals(0, MyHierarchy.MY_SUB_TYPE.doublePrimitivePropertyCount)
     	assertEquals(1, MyHierarchy.MY_SUB_TYPE.nonLongPrimitivePropertyCount)
     	assertEquals(Kind.Implementation, MyHierarchy.MY_SUB_TYPE.kind)
     	assertEquals(32, MyHierarchy.MY_SUB_TYPE.primitivePropertyBitsTotal)
     	assertEquals(4, MyHierarchy.MY_SUB_TYPE.primitivePropertyByteTotal)
     	assertEquals(8, MyHierarchy.MY_SUB_TYPE.footprint)
     	assertEquals(8 + MyHierarchy.MY_TYPE.footprint + Footprint.OBJECT_SIZE,
     		MyHierarchy.MY_SUB_TYPE.inheritedFootprint)

		val Map<String,com.blockwithme.meta.Property> map = newHashMap()
		map.putAll(MyHierarchy.MY_SUB_TYPE.simpleNameToProperty as Map)
		for (p : MyHierarchy.MY_SUB_TYPE.inheritedProperties) {
			assertEquals(p, map.remove(p.simpleName))
		}
    	assertTrue(map.empty)

    	assertFalse(MyHierarchy.MY_TYPE.isChildOf(MyHierarchy.MY_SUB_TYPE))
    	assertTrue(MyHierarchy.MY_SUB_TYPE.isChildOf(MyHierarchy.MY_TYPE))
    	assertFalse(MyHierarchy.MY_SUB_TYPE.isParentOf(MyHierarchy.MY_TYPE))
    	assertTrue(MyHierarchy.MY_TYPE.isParentOf(MyHierarchy.MY_SUB_TYPE))
    }

	// TODO Fails due to Xtend bug
//    @Test
//    public def void testCreate() {
//    	val obj = MyHierarchy.MY_TYPE.create
//    	assertEquals(MyType, obj.class)
//    }
}