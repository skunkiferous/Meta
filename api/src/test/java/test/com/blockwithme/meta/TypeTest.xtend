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
import com.blockwithme.meta.beans.Ref

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
class TypeTest extends BaseTst {
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
    	assertTrue(listener.hierarchies.contains(MetaTestHelper.TEST))
    	assertTrue(listener.types.contains(MetaTestHelper.MY_TYPE))
    	assertEquals(listener.metaProperties.size, 1)
    	assertTrue(listener.metaProperties.contains(MetaTestHelper.META_PROP))
    	// Check that things registered *after* the listener gets passed to a new listener.
    	MyLazyLoadListenerTST.TST.toString
    	assertEquals(listener.metaProperties.size, 2)
    	assertTrue(listener.metaProperties.contains(MyLazyLoadListenerTST.TST))
	}

    @Test
    public def void testPropGet() {
    	val obj = new MyType

    	assertEquals(false, MetaTestHelper.BOOL_PROP.getBoolean(obj))
    	assertEquals(0 as byte, MetaTestHelper.BYTE_PROP.getByte(obj))
    	assertEquals(0 as short, MetaTestHelper.SHORT_PROP.getShort(obj))
    	assertEquals(' '.charAt(0), MetaTestHelper.CHAR_PROP.getChar(obj))
    	assertEquals(0, MetaTestHelper.INT_PROP.getInt(obj))
    	assertEquals(0L, MetaTestHelper.LONG_PROP.getLong(obj))
    	assertEquals(0.0f, MetaTestHelper.FLOAT_PROP.getFloat(obj), 0.001f)
    	assertEquals(0.0, MetaTestHelper.DOUBLE_PROP.getDouble(obj), 0.001)
    	assertEquals("", MetaTestHelper.OBJECT_PROP.getObject(obj))
    	assertEquals(MyEnum.A, MetaTestHelper.ENUM_PROP.getObject(obj))
    	assertEquals(false, MetaTestHelper.VIRTUAL_BOOL_PROP.getBoolean(obj))

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

    	assertEquals(true, MetaTestHelper.BOOL_PROP.getBoolean(obj))
    	assertEquals(42 as byte, MetaTestHelper.BYTE_PROP.getByte(obj))
    	assertEquals(42 as short, MetaTestHelper.SHORT_PROP.getShort(obj))
    	assertEquals('\u0042'.charAt(0), MetaTestHelper.CHAR_PROP.getChar(obj))
    	assertEquals(42, MetaTestHelper.INT_PROP.getInt(obj))
    	assertEquals(42L, MetaTestHelper.LONG_PROP.getLong(obj))
    	assertEquals(42.0f, MetaTestHelper.FLOAT_PROP.getFloat(obj), 0.001f)
    	assertEquals(42.0, MetaTestHelper.DOUBLE_PROP.getDouble(obj), 0.001)
    	assertEquals("42", MetaTestHelper.OBJECT_PROP.getObject(obj))
    	assertEquals(MyEnum.C, MetaTestHelper.ENUM_PROP.getObject(obj))
    	assertEquals(true, MetaTestHelper.VIRTUAL_BOOL_PROP.getBoolean(obj))
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

    	assertEquals(obj, MetaTestHelper.BOOL_PROP.setBoolean(obj, true))
    	assertEquals(obj, MetaTestHelper.BYTE_PROP.setByte(obj, 42 as byte))
    	assertEquals(obj, MetaTestHelper.SHORT_PROP.setShort(obj, 42 as short))
    	assertEquals(obj, MetaTestHelper.CHAR_PROP.setChar(obj, '\u0042')) // 42 Hex, not 42 decimal!
    	assertEquals(obj, MetaTestHelper.INT_PROP.setInt(obj, 42))
    	assertEquals(obj, MetaTestHelper.LONG_PROP.setLong(obj, 42L))
    	assertEquals(obj, MetaTestHelper.FLOAT_PROP.setFloat(obj, 42.0f))
    	assertEquals(obj, MetaTestHelper.DOUBLE_PROP.setDouble(obj, 42.0))
    	assertEquals(obj, MetaTestHelper.OBJECT_PROP.setObject(obj, "42"))
    	assertEquals(obj, MetaTestHelper.ENUM_PROP.setInt(obj, EnumConverter.DEFAULT.fromObject(obj, MyEnum.C)))

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

    	assertEquals(obj, MetaTestHelper.VIRTUAL_BOOL_PROP.setBoolean(obj, false))
    	assertEquals(false, obj.boolProp)
    }

    @Test
    public def void testPropGetObject() {
    	val obj = new MyType

    	assertEquals(Boolean.FALSE, MetaTestHelper.BOOL_PROP.getObject(obj))
    	assertEquals(new Byte(0 as byte), MetaTestHelper.BYTE_PROP.getObject(obj))
    	assertEquals(new Short(0 as short), MetaTestHelper.SHORT_PROP.getObject(obj))
    	assertEquals(new Character(' '.charAt(0)), MetaTestHelper.CHAR_PROP.getObject(obj))
    	assertEquals(new Integer(0), MetaTestHelper.INT_PROP.getObject(obj))
    	assertEquals(new Long(0L), MetaTestHelper.LONG_PROP.getObject(obj))
    	assertEquals(new Float(0.0f), MetaTestHelper.FLOAT_PROP.getObject(obj))
    	assertEquals(new Double(0.0), MetaTestHelper.DOUBLE_PROP.getObject(obj))
    	assertEquals("", MetaTestHelper.OBJECT_PROP.getObject(obj))
    	assertEquals(MyEnum.A, MetaTestHelper.ENUM_PROP.getObject(obj))
    	assertEquals(Boolean.FALSE, MetaTestHelper.VIRTUAL_BOOL_PROP.getObject(obj))

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

    	assertEquals(Boolean.TRUE, MetaTestHelper.BOOL_PROP.getObject(obj))
    	assertEquals(new Byte(42 as byte), MetaTestHelper.BYTE_PROP.getObject(obj))
    	assertEquals(new Short(42 as short), MetaTestHelper.SHORT_PROP.getObject(obj))
    	assertEquals(new Character('\u0042'.charAt(0)), MetaTestHelper.CHAR_PROP.getObject(obj))
    	assertEquals(new Integer(42), MetaTestHelper.INT_PROP.getObject(obj))
    	assertEquals(new Long(42L), MetaTestHelper.LONG_PROP.getObject(obj))
    	assertEquals(new Float(42.0f), MetaTestHelper.FLOAT_PROP.getObject(obj))
    	assertEquals(new Double(42.0), MetaTestHelper.DOUBLE_PROP.getObject(obj))
    	assertEquals("42", MetaTestHelper.OBJECT_PROP.getObject(obj))
    	assertEquals(MyEnum.C, MetaTestHelper.ENUM_PROP.getObject(obj))
    	assertEquals(Boolean.TRUE, MetaTestHelper.VIRTUAL_BOOL_PROP.getObject(obj))
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

    	MetaTestHelper.BOOL_PROP.setObject(obj, true)
    	MetaTestHelper.BYTE_PROP.setObject(obj, 42 as byte)
    	MetaTestHelper.SHORT_PROP.setObject(obj, 42 as short)
    	MetaTestHelper.CHAR_PROP.setObject(obj, '\u0042') // 42 Hex, not 42 decimal!
    	MetaTestHelper.INT_PROP.setObject(obj, 42)
    	MetaTestHelper.LONG_PROP.setObject(obj, 42L)
    	MetaTestHelper.FLOAT_PROP.setObject(obj, 42.0f)
    	MetaTestHelper.DOUBLE_PROP.setObject(obj, 42.0)
    	MetaTestHelper.OBJECT_PROP.setObject(obj, "42")
    	MetaTestHelper.ENUM_PROP.setObject(obj, MyEnum.C)

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

    	MetaTestHelper.VIRTUAL_BOOL_PROP.setObject(obj, false)
    	assertEquals(false, obj.boolProp)
    }

    @Test
    public def void testMetaProp() {
    	// Actual value could change, depending on how often the test is run!
    	val before = MetaTestHelper.META_PROP.getObject(MetaTestHelper.MY_TYPE)
    	val Boolean after = !before
    	MetaTestHelper.META_PROP.setObject(MetaTestHelper.MY_TYPE, after)
     	assertEquals(after, MetaTestHelper.META_PROP.getObject(MetaTestHelper.MY_TYPE))
    	assertTrue(MetaTestHelper.META_PROP.shared)
    	assertTrue(MetaTestHelper.META_PROP.actualInstance)
    	assertFalse(MetaTestHelper.META_PROP.exactType)
     	assertEquals(Boolean.FALSE, MetaTestHelper.META_PROP.defaultValue)
     	assertEquals(0, MetaTestHelper.META_PROP.globalPropertyId)
     	assertEquals(0, MetaTestHelper.META_PROP.propertyId)
     	assertEquals(0, MetaTestHelper.META_PROP.objectPropertyId)
     	assertEquals(0, MetaTestHelper.META_PROP.longOrObjectPropertyId)
    }

    @Test
    public def void testNames() {
     	assertEquals("MyType", MetaTestHelper.MY_TYPE.simpleName)
     	assertEquals("test.com.blockwithme.meta.MyType", MetaTestHelper.MY_TYPE.fullName)
     	assertEquals("meta", MetaTestHelper.MY_TYPE.pkg.simpleName)
     	assertEquals("test.com.blockwithme.meta", MetaTestHelper.MY_TYPE.pkg.fullName)
     	assertEquals("persistent", MetaTestHelper.META_PROP.simpleName)
     	assertEquals("com.blockwithme.meta.Type.persistent", MetaTestHelper.META_PROP.fullName)
     	assertEquals("boolProp", MetaTestHelper.BOOL_PROP.simpleName)
     	assertEquals("test.com.blockwithme.meta.MyType.boolProp", MetaTestHelper.BOOL_PROP.fullName)
    }

    @Test
    public def void testMetaBaseHierarchy() {
     	assertEquals(MetaTestHelper.TEST, MetaTestHelper.MY_TYPE.pkg.hierarchy)
     	assertEquals(MetaTestHelper.TEST, MetaTestHelper.MY_TYPE.hierarchy)
     	assertEquals(MetaTestHelper.TEST, MetaTestHelper.BOOL_PROP.hierarchy)
     	assertEquals(com.blockwithme.meta.Meta.HIERARCHY, MetaTestHelper.META_PROP.hierarchy)
    }

    @Test
    public def void testPropContentType() {
    	assertEquals(JavaMeta.BOOLEAN, MetaTestHelper.BOOL_PROP.contentType)
    	assertEquals(JavaMeta.BYTE, MetaTestHelper.BYTE_PROP.contentType)
    	assertEquals(JavaMeta.SHORT, MetaTestHelper.SHORT_PROP.contentType)
    	assertEquals(JavaMeta.CHARACTER, MetaTestHelper.CHAR_PROP.contentType)
    	assertEquals(JavaMeta.INTEGER, MetaTestHelper.INT_PROP.contentType)
    	assertEquals(JavaMeta.LONG, MetaTestHelper.LONG_PROP.contentType)
    	assertEquals(JavaMeta.FLOAT, MetaTestHelper.FLOAT_PROP.contentType)
    	assertEquals(JavaMeta.DOUBLE, MetaTestHelper.DOUBLE_PROP.contentType)
    	assertEquals(JavaMeta.STRING, MetaTestHelper.OBJECT_PROP.contentType)
    	assertEquals(MetaTestHelper.ENUM_TYPE, MetaTestHelper.ENUM_PROP.contentType)
    	assertEquals(JavaMeta.BOOLEAN, MetaTestHelper.VIRTUAL_BOOL_PROP.contentType)
    }

    @Test
    public def void testPropType() {
    	assertEquals(PropertyType.BOOLEAN, MetaTestHelper.BOOL_PROP.type)
    	assertEquals(PropertyType.BYTE, MetaTestHelper.BYTE_PROP.type)
    	assertEquals(PropertyType.SHORT, MetaTestHelper.SHORT_PROP.type)
    	assertEquals(PropertyType.CHARACTER, MetaTestHelper.CHAR_PROP.type)
    	assertEquals(PropertyType.INTEGER, MetaTestHelper.INT_PROP.type)
    	assertEquals(PropertyType.LONG, MetaTestHelper.LONG_PROP.type)
    	assertEquals(PropertyType.FLOAT, MetaTestHelper.FLOAT_PROP.type)
    	assertEquals(PropertyType.DOUBLE, MetaTestHelper.DOUBLE_PROP.type)
    	assertEquals(PropertyType.OBJECT, MetaTestHelper.OBJECT_PROP.type)
    	assertEquals(PropertyType.INTEGER, MetaTestHelper.ENUM_PROP.type)
    	assertEquals(PropertyType.BOOLEAN, MetaTestHelper.VIRTUAL_BOOL_PROP.type)
    }

    @Test
    public def void testPropPrimitive() {
    	assertTrue(MetaTestHelper.BOOL_PROP.primitive)
    	assertTrue(MetaTestHelper.BYTE_PROP.primitive)
    	assertTrue(MetaTestHelper.SHORT_PROP.primitive)
    	assertTrue(MetaTestHelper.CHAR_PROP.primitive)
    	assertTrue(MetaTestHelper.INT_PROP.primitive)
    	assertTrue(MetaTestHelper.LONG_PROP.primitive)
    	assertTrue(MetaTestHelper.FLOAT_PROP.primitive)
    	assertTrue(MetaTestHelper.DOUBLE_PROP.primitive)
    	assertFalse(MetaTestHelper.OBJECT_PROP.primitive)
    	assertFalse(MetaTestHelper.ENUM_PROP.primitive)
    	assertFalse(MetaTestHelper.META_PROP.primitive)
    	assertTrue(MetaTestHelper.VIRTUAL_BOOL_PROP.primitive)
    }

    @Test
    public def void testPropMeta() {
    	assertFalse(MetaTestHelper.BOOL_PROP.meta)
    	assertFalse(MetaTestHelper.BYTE_PROP.meta)
    	assertFalse(MetaTestHelper.SHORT_PROP.meta)
    	assertFalse(MetaTestHelper.CHAR_PROP.meta)
    	assertFalse(MetaTestHelper.INT_PROP.meta)
    	assertFalse(MetaTestHelper.LONG_PROP.meta)
    	assertFalse(MetaTestHelper.FLOAT_PROP.meta)
    	assertFalse(MetaTestHelper.DOUBLE_PROP.meta)
    	assertFalse(MetaTestHelper.OBJECT_PROP.meta)
    	assertTrue(MetaTestHelper.META_PROP.meta)
    	assertFalse(MetaTestHelper.ENUM_PROP.meta)
    	assertFalse(MetaTestHelper.VIRTUAL_BOOL_PROP.meta)
    }

    @Test
    public def void testPrimPropFloatingPoint() {
    	assertFalse(MetaTestHelper.BOOL_PROP.floatingPoint)
    	assertFalse(MetaTestHelper.BYTE_PROP.floatingPoint)
    	assertFalse(MetaTestHelper.SHORT_PROP.floatingPoint)
    	assertFalse(MetaTestHelper.CHAR_PROP.floatingPoint)
    	assertFalse(MetaTestHelper.INT_PROP.floatingPoint)
    	assertFalse(MetaTestHelper.LONG_PROP.floatingPoint)
    	assertTrue(MetaTestHelper.FLOAT_PROP.floatingPoint)
    	assertTrue(MetaTestHelper.DOUBLE_PROP.floatingPoint)
    	assertFalse(MetaTestHelper.ENUM_PROP.floatingPoint)
    	assertFalse(MetaTestHelper.VIRTUAL_BOOL_PROP.floatingPoint)
    }

    @Test
    public def void testPrimPropSixtyFourBit() {
    	assertFalse(MetaTestHelper.BOOL_PROP.sixtyFourBit)
    	assertFalse(MetaTestHelper.BYTE_PROP.sixtyFourBit)
    	assertFalse(MetaTestHelper.SHORT_PROP.sixtyFourBit)
    	assertFalse(MetaTestHelper.CHAR_PROP.sixtyFourBit)
    	assertFalse(MetaTestHelper.INT_PROP.sixtyFourBit)
    	assertTrue(MetaTestHelper.LONG_PROP.sixtyFourBit)
    	assertFalse(MetaTestHelper.FLOAT_PROP.sixtyFourBit)
    	assertTrue(MetaTestHelper.DOUBLE_PROP.sixtyFourBit)
    	assertFalse(MetaTestHelper.ENUM_PROP.sixtyFourBit)
    	assertFalse(MetaTestHelper.VIRTUAL_BOOL_PROP.sixtyFourBit)
    }

    @Test
    public def void testPrimPropSigned() {
    	assertFalse(MetaTestHelper.BOOL_PROP.signed)
    	assertTrue(MetaTestHelper.BYTE_PROP.signed)
    	assertTrue(MetaTestHelper.SHORT_PROP.signed)
    	assertFalse(MetaTestHelper.CHAR_PROP.signed)
    	assertTrue(MetaTestHelper.INT_PROP.signed)
    	assertTrue(MetaTestHelper.LONG_PROP.signed)
    	assertTrue(MetaTestHelper.FLOAT_PROP.signed)
    	assertTrue(MetaTestHelper.DOUBLE_PROP.signed)
    	assertTrue(MetaTestHelper.ENUM_PROP.signed)
    	assertFalse(MetaTestHelper.VIRTUAL_BOOL_PROP.signed)
    }

    @Test
    public def void testPrimPropWrapper() {
    	assertTrue(MetaTestHelper.BOOL_PROP.wrapper)
    	assertTrue(MetaTestHelper.BYTE_PROP.wrapper)
    	assertTrue(MetaTestHelper.SHORT_PROP.wrapper)
    	assertTrue(MetaTestHelper.CHAR_PROP.wrapper)
    	assertTrue(MetaTestHelper.INT_PROP.wrapper)
    	assertTrue(MetaTestHelper.LONG_PROP.wrapper)
    	assertTrue(MetaTestHelper.FLOAT_PROP.wrapper)
    	assertTrue(MetaTestHelper.DOUBLE_PROP.wrapper)
    	assertFalse(MetaTestHelper.ENUM_PROP.wrapper)
    	assertTrue(MetaTestHelper.VIRTUAL_BOOL_PROP.wrapper)
    }

    @Test
    public def void testPrimPropBits() {
    	assertEquals(1, MetaTestHelper.BOOL_PROP.bits)
    	assertEquals(8, MetaTestHelper.BYTE_PROP.bits)
    	assertEquals(16, MetaTestHelper.SHORT_PROP.bits)
    	assertEquals(16, MetaTestHelper.CHAR_PROP.bits)
    	assertEquals(32, MetaTestHelper.INT_PROP.bits)
    	assertEquals(64, MetaTestHelper.LONG_PROP.bits)
    	assertEquals(32, MetaTestHelper.FLOAT_PROP.bits)
    	assertEquals(64, MetaTestHelper.DOUBLE_PROP.bits)
    	assertEquals(32, MetaTestHelper.ENUM_PROP.bits)
    	assertEquals(1, MetaTestHelper.VIRTUAL_BOOL_PROP.bits)
    }

    @Test
    public def void testPrimPropBytes() {
    	assertEquals(1, MetaTestHelper.BOOL_PROP.bytes)
    	assertEquals(1, MetaTestHelper.BYTE_PROP.bytes)
    	assertEquals(2, MetaTestHelper.SHORT_PROP.bytes)
    	assertEquals(2, MetaTestHelper.CHAR_PROP.bytes)
    	assertEquals(4, MetaTestHelper.INT_PROP.bytes)
    	assertEquals(8, MetaTestHelper.LONG_PROP.bytes)
    	assertEquals(4, MetaTestHelper.FLOAT_PROP.bytes)
    	assertEquals(8, MetaTestHelper.DOUBLE_PROP.bytes)
    	assertEquals(4, MetaTestHelper.ENUM_PROP.bytes)
    	assertEquals(1, MetaTestHelper.VIRTUAL_BOOL_PROP.bytes)
    }

    @Test
    public def void testPrimPropConverter() {
    	assertEquals(BooleanConverter.DEFAULT, MetaTestHelper.BOOL_PROP.converter)
    	assertEquals(ByteConverter.DEFAULT, MetaTestHelper.BYTE_PROP.converter)
    	assertEquals(ShortConverter.DEFAULT, MetaTestHelper.SHORT_PROP.converter)
    	assertEquals(CharConverter.DEFAULT, MetaTestHelper.CHAR_PROP.converter)
    	assertEquals(IntConverter.DEFAULT, MetaTestHelper.INT_PROP.converter)
    	assertEquals(LongConverter.DEFAULT, MetaTestHelper.LONG_PROP.converter)
    	assertEquals(FloatConverter.DEFAULT, MetaTestHelper.FLOAT_PROP.converter)
    	assertEquals(DoubleConverter.DEFAULT, MetaTestHelper.DOUBLE_PROP.converter)
    	assertEquals(EnumConverter.DEFAULT, MetaTestHelper.ENUM_PROP.converter)
    	assertEquals(BooleanConverter.DEFAULT, MetaTestHelper.VIRTUAL_BOOL_PROP.converter)
    }

    @Test
    public def void testPropOwner() {
    	assertEquals(MetaTestHelper.MY_TYPE, MetaTestHelper.BOOL_PROP.owner)
    	assertEquals(MetaTestHelper.MY_TYPE, MetaTestHelper.BYTE_PROP.owner)
    	assertEquals(MetaTestHelper.MY_TYPE, MetaTestHelper.SHORT_PROP.owner)
    	assertEquals(MetaTestHelper.MY_TYPE, MetaTestHelper.CHAR_PROP.owner)
    	assertEquals(MetaTestHelper.MY_TYPE, MetaTestHelper.INT_PROP.owner)
    	assertEquals(MetaTestHelper.MY_TYPE, MetaTestHelper.LONG_PROP.owner)
    	assertEquals(MetaTestHelper.MY_TYPE, MetaTestHelper.FLOAT_PROP.owner)
    	assertEquals(MetaTestHelper.MY_TYPE, MetaTestHelper.DOUBLE_PROP.owner)
    	assertEquals(com.blockwithme.meta.Meta.TYPE, MetaTestHelper.META_PROP.owner)
    	assertEquals(MetaTestHelper.MY_TYPE, MetaTestHelper.ENUM_PROP.owner)
    	assertEquals(MetaTestHelper.MY_TYPE, MetaTestHelper.VIRTUAL_BOOL_PROP.owner)
    }

    @Test
    public def void testVirtualPropIDs() {
    	assertEquals(-1, MetaTestHelper.BOOL_PROP.virtualPropertyId)
    	assertEquals(-1, MetaTestHelper.BYTE_PROP.virtualPropertyId)
    	assertEquals(-1, MetaTestHelper.SHORT_PROP.virtualPropertyId)
    	assertEquals(-1, MetaTestHelper.CHAR_PROP.virtualPropertyId)
    	assertEquals(-1, MetaTestHelper.INT_PROP.virtualPropertyId)
    	assertEquals(-1, MetaTestHelper.LONG_PROP.virtualPropertyId)
    	assertEquals(-1, MetaTestHelper.FLOAT_PROP.virtualPropertyId)
    	assertEquals(-1, MetaTestHelper.DOUBLE_PROP.virtualPropertyId)
    	assertEquals(-1, MetaTestHelper.ENUM_PROP.virtualPropertyId)
    	assertEquals(0, MetaTestHelper.VIRTUAL_BOOL_PROP.virtualPropertyId)
    }

    @Test
    public def void testBoolProp() {
     	assertEquals(0, MetaTestHelper.BOOL_PROP.globalPropertyId)
     	assertEquals(0, MetaTestHelper.BOOL_PROP.propertyId)
     	assertEquals(0, MetaTestHelper.BOOL_PROP.primitivePropertyId)
     	assertEquals(0, MetaTestHelper.BOOL_PROP.booleanPropertyId)
     	assertEquals(0, MetaTestHelper.BOOL_PROP.nonSixtyFourBitPropertyId)
     	assertEquals(-1, MetaTestHelper.BOOL_PROP.sixtyFourBitPropertyId)
     	assertEquals(0, MetaTestHelper.BOOL_PROP.nonLongPropertyId)
     	assertEquals(-1, MetaTestHelper.BOOL_PROP.longOrObjectPropertyId)
    }

    @Test
    public def void testByteProp() {
     	assertEquals(1, MetaTestHelper.BYTE_PROP.globalPropertyId)
     	assertEquals(1, MetaTestHelper.BYTE_PROP.propertyId)
     	assertEquals(1, MetaTestHelper.BYTE_PROP.primitivePropertyId)
     	assertEquals(0, MetaTestHelper.BYTE_PROP.bytePropertyId)
     	assertEquals(1, MetaTestHelper.BYTE_PROP.nonSixtyFourBitPropertyId)
     	assertEquals(-1, MetaTestHelper.BYTE_PROP.sixtyFourBitPropertyId)
     	assertEquals(1, MetaTestHelper.BYTE_PROP.nonLongPropertyId)
     	assertEquals(-1, MetaTestHelper.BYTE_PROP.longOrObjectPropertyId)
    }

    @Test
    public def void testCharProp() {
     	assertEquals(2, MetaTestHelper.CHAR_PROP.globalPropertyId)
     	assertEquals(2, MetaTestHelper.CHAR_PROP.propertyId)
     	assertEquals(2, MetaTestHelper.CHAR_PROP.primitivePropertyId)
     	assertEquals(0, MetaTestHelper.CHAR_PROP.characterPropertyId)
     	assertEquals(2, MetaTestHelper.CHAR_PROP.nonSixtyFourBitPropertyId)
     	assertEquals(-1, MetaTestHelper.CHAR_PROP.sixtyFourBitPropertyId)
     	assertEquals(2, MetaTestHelper.CHAR_PROP.nonLongPropertyId)
     	assertEquals(-1, MetaTestHelper.CHAR_PROP.longOrObjectPropertyId)
    }

    @Test
    public def void testShortProp() {
     	assertEquals(3, MetaTestHelper.SHORT_PROP.globalPropertyId)
     	assertEquals(3, MetaTestHelper.SHORT_PROP.propertyId)
     	assertEquals(3, MetaTestHelper.SHORT_PROP.primitivePropertyId)
     	assertEquals(0, MetaTestHelper.SHORT_PROP.shortPropertyId)
     	assertEquals(3, MetaTestHelper.SHORT_PROP.nonSixtyFourBitPropertyId)
     	assertEquals(-1, MetaTestHelper.SHORT_PROP.sixtyFourBitPropertyId)
     	assertEquals(3, MetaTestHelper.SHORT_PROP.nonLongPropertyId)
     	assertEquals(-1, MetaTestHelper.SHORT_PROP.longOrObjectPropertyId)
    }

    @Test
    public def void testIntProp() {
     	assertEquals(4, MetaTestHelper.INT_PROP.globalPropertyId)
     	assertEquals(4, MetaTestHelper.INT_PROP.propertyId)
     	assertEquals(4, MetaTestHelper.INT_PROP.primitivePropertyId)
     	assertEquals(0, MetaTestHelper.INT_PROP.integerPropertyId)
     	assertEquals(4, MetaTestHelper.INT_PROP.nonSixtyFourBitPropertyId)
     	assertEquals(-1, MetaTestHelper.INT_PROP.sixtyFourBitPropertyId)
     	assertEquals(4, MetaTestHelper.INT_PROP.nonLongPropertyId)
     	assertEquals(-1, MetaTestHelper.INT_PROP.longOrObjectPropertyId)
    }

    @Test
    public def void testLongProp() {
     	assertEquals(5, MetaTestHelper.LONG_PROP.globalPropertyId)
     	assertEquals(5, MetaTestHelper.LONG_PROP.propertyId)
     	assertEquals(5, MetaTestHelper.LONG_PROP.primitivePropertyId)
     	assertEquals(0, MetaTestHelper.LONG_PROP.longPropertyId)
     	assertEquals(-1, MetaTestHelper.LONG_PROP.nonSixtyFourBitPropertyId)
     	assertEquals(0, MetaTestHelper.LONG_PROP.sixtyFourBitPropertyId)
     	assertEquals(-1, MetaTestHelper.LONG_PROP.nonLongPropertyId)
     	assertEquals(0, MetaTestHelper.LONG_PROP.longOrObjectPropertyId)
    }

    @Test
    public def void testFloatProp() {
     	assertEquals(6, MetaTestHelper.FLOAT_PROP.globalPropertyId)
     	assertEquals(6, MetaTestHelper.FLOAT_PROP.propertyId)
     	assertEquals(6, MetaTestHelper.FLOAT_PROP.primitivePropertyId)
     	assertEquals(0, MetaTestHelper.FLOAT_PROP.floatPropertyId)
     	assertEquals(5, MetaTestHelper.FLOAT_PROP.nonSixtyFourBitPropertyId)
     	assertEquals(-1, MetaTestHelper.FLOAT_PROP.sixtyFourBitPropertyId)
     	assertEquals(5, MetaTestHelper.FLOAT_PROP.nonLongPropertyId)
     	assertEquals(-1, MetaTestHelper.FLOAT_PROP.longOrObjectPropertyId)
    }

    @Test
    public def void testDoubleProp() {
     	assertEquals(7, MetaTestHelper.DOUBLE_PROP.globalPropertyId)
     	assertEquals(7, MetaTestHelper.DOUBLE_PROP.propertyId)
     	assertEquals(7, MetaTestHelper.DOUBLE_PROP.primitivePropertyId)
     	assertEquals(0, MetaTestHelper.DOUBLE_PROP.doublePropertyId)
     	assertEquals(-1, MetaTestHelper.DOUBLE_PROP.nonSixtyFourBitPropertyId)
     	assertEquals(1, MetaTestHelper.DOUBLE_PROP.sixtyFourBitPropertyId)
     	assertEquals(6, MetaTestHelper.DOUBLE_PROP.nonLongPropertyId)
     	assertEquals(-1, MetaTestHelper.DOUBLE_PROP.longOrObjectPropertyId)
    }

    @Test
    public def void testObjectProp() {
     	assertEquals(8, MetaTestHelper.OBJECT_PROP.globalPropertyId)
     	assertEquals(8, MetaTestHelper.OBJECT_PROP.propertyId)
     	assertEquals(0, MetaTestHelper.OBJECT_PROP.objectPropertyId)
     	assertEquals(1, MetaTestHelper.OBJECT_PROP.longOrObjectPropertyId)
    	assertTrue(MetaTestHelper.OBJECT_PROP.shared)
    	assertTrue(MetaTestHelper.OBJECT_PROP.actualInstance)
    	assertTrue(MetaTestHelper.OBJECT_PROP.exactType)
    }

    @Test
    public def void testEnumProp() {
     	assertEquals(9, MetaTestHelper.ENUM_PROP.globalPropertyId)
     	assertEquals(9, MetaTestHelper.ENUM_PROP.propertyId)
     	assertEquals(8, MetaTestHelper.ENUM_PROP.primitivePropertyId)
     	assertEquals(1, MetaTestHelper.ENUM_PROP.integerPropertyId)
     	assertEquals(6, MetaTestHelper.ENUM_PROP.nonSixtyFourBitPropertyId)
     	assertEquals(-1, MetaTestHelper.ENUM_PROP.sixtyFourBitPropertyId)
     	assertEquals(7, MetaTestHelper.ENUM_PROP.nonLongPropertyId)
     	assertEquals(-1, MetaTestHelper.ENUM_PROP.longOrObjectPropertyId)
    }

    @Test
    public def void testInt2Prop() {
     	assertEquals(10, MetaTestHelper.INT_PROP2.globalPropertyId)
     	assertEquals(0, MetaTestHelper.INT_PROP2.propertyId)
     	assertEquals(0, MetaTestHelper.INT_PROP2.primitivePropertyId)
     	assertEquals(0, MetaTestHelper.INT_PROP2.integerPropertyId)
     	assertEquals(0, MetaTestHelper.INT_PROP2.nonSixtyFourBitPropertyId)
     	assertEquals(-1, MetaTestHelper.INT_PROP2.sixtyFourBitPropertyId)
     	assertEquals(0, MetaTestHelper.INT_PROP2.nonLongPropertyId)
     	assertEquals(-1, MetaTestHelper.INT_PROP2.longOrObjectPropertyId)
    }

    @Test
    public def void testVirtualBoolProp() {
     	assertEquals(11, MetaTestHelper.VIRTUAL_BOOL_PROP.globalPropertyId)
     	assertEquals(10, MetaTestHelper.VIRTUAL_BOOL_PROP.propertyId)
     	assertEquals(-1, MetaTestHelper.VIRTUAL_BOOL_PROP.primitivePropertyId)
     	assertEquals(-1, MetaTestHelper.VIRTUAL_BOOL_PROP.booleanPropertyId)
     	assertEquals(-1, MetaTestHelper.VIRTUAL_BOOL_PROP.nonSixtyFourBitPropertyId)
     	assertEquals(-1, MetaTestHelper.VIRTUAL_BOOL_PROP.sixtyFourBitPropertyId)
     	assertEquals(-1, MetaTestHelper.VIRTUAL_BOOL_PROP.nonLongPropertyId)
     	assertEquals(-1, MetaTestHelper.VIRTUAL_BOOL_PROP.longOrObjectPropertyId)
    }

    @Test
    public def void testTypePackage() {
     	assertEquals(0, MetaTestHelper.MY_TYPE.pkg.packageId)
     	assertEquals(MetaTestHelper.package, MetaTestHelper.MY_TYPE.pkg.pkg)
     	assertEquals(#[MetaTestHelper.MY_TYPE,MetaTestHelper.ENUM_TYPE,MetaTestHelper.MY_SUB_TYPE,MetaTestHelper.MY_COLLECTION_TYPE].toList,
     		MetaTestHelper.MY_TYPE.pkg.types.toList
     	)
    }

    @Test
    public def void testPropSameProperty() {
    	assertFalse(MetaTestHelper.OBJECT_PROP.sameProperty(null))
    	assertFalse(MetaTestHelper.OBJECT_PROP.sameProperty(MetaTestHelper.DOUBLE_PROP))
    	assertTrue(MetaTestHelper.OBJECT_PROP.sameProperty(MetaTestHelper.OBJECT_PROP))
    	// TODO Test two different property instance with same name
    }

    @Test
    public def void testHierarchy() {
//     	assertEquals(MyType, TestMeta.TEST.base)
     	assertEquals(newArrayList(JavaMeta.HIERARCHY,Meta.HIERARCHY), MetaTestHelper.TEST.dependencies.toList)
     	assertEquals(new HashSet(#[JavaMeta.HIERARCHY,com.blockwithme.meta.Meta.HIERARCHY,Meta.HIERARCHY,MetaTestHelper.TEST]),
     			new HashSet(Hierarchy.hierarchies.toList)
     	)
    }

    @Test
    public def void testType() {
     	assertEquals(MyType, MetaTestHelper.MY_TYPE.type)
     	assertFalse(MetaTestHelper.MY_TYPE.primitive)
     	assertEquals(0, MetaTestHelper.MY_TYPE.parents.length)
     	assertEquals(0, MetaTestHelper.MY_TYPE.inheritedParents.length)
     	assertEquals(newArrayList(MetaTestHelper.BOOL_PROP, MetaTestHelper.BYTE_PROP,
     		MetaTestHelper.CHAR_PROP, MetaTestHelper.SHORT_PROP, MetaTestHelper.INT_PROP,
     		MetaTestHelper.LONG_PROP, MetaTestHelper.FLOAT_PROP, MetaTestHelper.DOUBLE_PROP,
     		MetaTestHelper.OBJECT_PROP, MetaTestHelper.ENUM_PROP
     	).toSet, MetaTestHelper.MY_TYPE.properties.toSet)
     	assertEquals(newArrayList(MetaTestHelper.OBJECT_PROP), MetaTestHelper.MY_TYPE.objectProperties.toList)
     	assertEquals(MetaTestHelper.MY_TYPE.objectProperties.toList,
     		MetaTestHelper.MY_TYPE.inheritedObjectProperties.toList)
     	assertEquals(<Object>newArrayList(MetaTestHelper.BOOL_PROP, MetaTestHelper.BYTE_PROP,
     		MetaTestHelper.CHAR_PROP, MetaTestHelper.SHORT_PROP, MetaTestHelper.INT_PROP,
     		MetaTestHelper.LONG_PROP, MetaTestHelper.FLOAT_PROP, MetaTestHelper.DOUBLE_PROP,
     		MetaTestHelper.ENUM_PROP
     	).toSet, MetaTestHelper.MY_TYPE.primitiveProperties.toSet)
     	assertEquals(MetaTestHelper.MY_TYPE.primitiveProperties.toList,
     		MetaTestHelper.MY_TYPE.inheritedPrimitiveProperties.toList)
     	assertEquals(10, MetaTestHelper.MY_TYPE.inheritedProperties.length)
     	assertEquals(newArrayList(MetaTestHelper.VIRTUAL_BOOL_PROP
     	).toSet, MetaTestHelper.MY_TYPE.virtualProperties.toSet)
     	assertEquals(newArrayList(MetaTestHelper.VIRTUAL_BOOL_PROP
     	).toSet, MetaTestHelper.MY_TYPE.inheritedVirtualProperties.toSet)
     	assertEquals(10, MetaTestHelper.MY_TYPE.inheritedPropertyCount)
     	assertEquals(1, MetaTestHelper.MY_TYPE.typeId)
     	assertEquals(9, MetaTestHelper.MY_TYPE.primitivePropertyCount)
     	assertEquals(1, MetaTestHelper.MY_TYPE.objectPropertyCount)
     	assertEquals(10, MetaTestHelper.MY_TYPE.propertyCount)
     	assertEquals(2, MetaTestHelper.MY_TYPE.sixtyFourBitPropertyCount)
     	assertEquals(7, MetaTestHelper.MY_TYPE.nonSixtyFourBitPropertyCount)
     	assertEquals(1, MetaTestHelper.MY_TYPE.booleanPrimitivePropertyCount)
     	assertEquals(1, MetaTestHelper.MY_TYPE.bytePrimitivePropertyCount)
     	assertEquals(1, MetaTestHelper.MY_TYPE.charPrimitivePropertyCount)
     	assertEquals(1, MetaTestHelper.MY_TYPE.shortPrimitivePropertyCount)
     	assertEquals(2, MetaTestHelper.MY_TYPE.intPrimitivePropertyCount)
     	assertEquals(1, MetaTestHelper.MY_TYPE.longPrimitivePropertyCount)
     	assertEquals(1, MetaTestHelper.MY_TYPE.floatPrimitivePropertyCount)
     	assertEquals(1, MetaTestHelper.MY_TYPE.doublePrimitivePropertyCount)
     	assertEquals(8, MetaTestHelper.MY_TYPE.nonLongPrimitivePropertyCount)
     	assertEquals(Kind.Implementation, MetaTestHelper.MY_TYPE.kind)
     	assertEquals(265, MetaTestHelper.MY_TYPE.primitivePropertyBitsTotal)
     	assertEquals(34, MetaTestHelper.MY_TYPE.primitivePropertyByteTotal)
     	assertEquals(40, MetaTestHelper.MY_TYPE.footprint)
     	assertEquals(40 + Footprint.OBJECT_SIZE, MetaTestHelper.MY_TYPE.inheritedFootprint)

		val Map<String,com.blockwithme.meta.Property> map = newHashMap()
		map.putAll(MetaTestHelper.MY_TYPE.simpleNameToProperty as Map)
		for (p : MetaTestHelper.MY_TYPE.properties) {
			assertEquals(p, map.remove(p.simpleName))
		}
		for (p : MetaTestHelper.MY_TYPE.virtualProperties) {
			assertEquals(p, map.remove(p.simpleName))
		}
    	assertTrue(map.empty)

    	assertFalse(MetaTestHelper.MY_TYPE.sameType(null))
    	assertFalse(MetaTestHelper.MY_TYPE.sameType(JavaMeta.STRING))
    	assertTrue(MetaTestHelper.MY_TYPE.sameType(MetaTestHelper.MY_TYPE))
    	assertTrue(MetaTestHelper.OBJECT2.sameType(JavaMeta.OBJECT))

    	assertFalse(MetaTestHelper.OBJECT2.isChildOf(MetaTestHelper.MY_TYPE))
    	assertTrue(JavaMeta.STRING.isChildOf(JavaMeta.CHAR_SEQUENCE))
    	assertFalse(MetaTestHelper.MY_TYPE.isParentOf(JavaMeta.STRING))
    	assertTrue(JavaMeta.CHAR_SEQUENCE.isParentOf(JavaMeta.STRING))
    }

    @Test
    public def void testSubType() {
     	assertEquals(MySubType, MetaTestHelper.MY_SUB_TYPE.type)
     	assertFalse(MetaTestHelper.MY_SUB_TYPE.primitive)
     	assertEquals(1, MetaTestHelper.MY_SUB_TYPE.parents.length)
     	assertEquals(MyType, MetaTestHelper.MY_SUB_TYPE.parents.get(0).type)
     	assertEquals(1, MetaTestHelper.MY_SUB_TYPE.inheritedParents.length)
     	assertEquals(MyType, MetaTestHelper.MY_SUB_TYPE.inheritedParents.get(0).type)
     	assertEquals(newArrayList(MetaTestHelper.INT_PROP2).toSet,
     		MetaTestHelper.MY_SUB_TYPE.properties.toSet)
     	assertEquals(0, MetaTestHelper.MY_SUB_TYPE.objectProperties.length)
     	assertEquals(newArrayList(MetaTestHelper.INT_PROP2).toSet,
     		MetaTestHelper.MY_SUB_TYPE.primitiveProperties.toSet)
     	assertEquals(newArrayList(MetaTestHelper.BOOL_PROP, MetaTestHelper.BYTE_PROP,
     		MetaTestHelper.CHAR_PROP, MetaTestHelper.SHORT_PROP, MetaTestHelper.INT_PROP,
     		MetaTestHelper.LONG_PROP, MetaTestHelper.FLOAT_PROP, MetaTestHelper.DOUBLE_PROP,
     		MetaTestHelper.OBJECT_PROP, MetaTestHelper.ENUM_PROP, MetaTestHelper.INT_PROP2
     	).toSet, MetaTestHelper.MY_SUB_TYPE.inheritedProperties.toSet)
     	assertEquals(11, MetaTestHelper.MY_SUB_TYPE.inheritedProperties.length)
     	assertEquals(11, MetaTestHelper.MY_SUB_TYPE.inheritedPropertyCount)
     	assertEquals(2, MetaTestHelper.MY_SUB_TYPE.typeId)
     	assertEquals(1, MetaTestHelper.MY_SUB_TYPE.primitivePropertyCount)
     	assertEquals(0, MetaTestHelper.MY_SUB_TYPE.objectPropertyCount)
     	assertEquals(1, MetaTestHelper.MY_SUB_TYPE.propertyCount)
     	assertEquals(0, MetaTestHelper.MY_SUB_TYPE.sixtyFourBitPropertyCount)
     	assertEquals(1, MetaTestHelper.MY_SUB_TYPE.nonSixtyFourBitPropertyCount)
     	assertEquals(0, MetaTestHelper.MY_SUB_TYPE.booleanPrimitivePropertyCount)
     	assertEquals(0, MetaTestHelper.MY_SUB_TYPE.bytePrimitivePropertyCount)
     	assertEquals(0, MetaTestHelper.MY_SUB_TYPE.charPrimitivePropertyCount)
     	assertEquals(0, MetaTestHelper.MY_SUB_TYPE.shortPrimitivePropertyCount)
     	assertEquals(1, MetaTestHelper.MY_SUB_TYPE.intPrimitivePropertyCount)
     	assertEquals(0, MetaTestHelper.MY_SUB_TYPE.longPrimitivePropertyCount)
     	assertEquals(0, MetaTestHelper.MY_SUB_TYPE.floatPrimitivePropertyCount)
     	assertEquals(0, MetaTestHelper.MY_SUB_TYPE.doublePrimitivePropertyCount)
     	assertEquals(1, MetaTestHelper.MY_SUB_TYPE.nonLongPrimitivePropertyCount)
     	assertEquals(Kind.Implementation, MetaTestHelper.MY_SUB_TYPE.kind)
     	assertEquals(32, MetaTestHelper.MY_SUB_TYPE.primitivePropertyBitsTotal)
     	assertEquals(4, MetaTestHelper.MY_SUB_TYPE.primitivePropertyByteTotal)
     	assertEquals(8, MetaTestHelper.MY_SUB_TYPE.footprint)
     	assertEquals(8 + MetaTestHelper.MY_TYPE.footprint + Footprint.OBJECT_SIZE,
     		MetaTestHelper.MY_SUB_TYPE.inheritedFootprint)

		val Map<String,com.blockwithme.meta.Property> map = newHashMap()
		map.putAll(MetaTestHelper.MY_SUB_TYPE.simpleNameToProperty as Map)
		for (p : MetaTestHelper.MY_SUB_TYPE.inheritedProperties) {
			assertEquals(p, map.remove(p.simpleName))
		}
		for (p : MetaTestHelper.MY_SUB_TYPE.inheritedVirtualProperties) {
			assertEquals(p, map.remove(p.simpleName))
		}
    	assertTrue(map.empty)

    	assertFalse(MetaTestHelper.MY_TYPE.isChildOf(MetaTestHelper.MY_SUB_TYPE))
    	assertTrue(MetaTestHelper.MY_SUB_TYPE.isChildOf(MetaTestHelper.MY_TYPE))
    	assertFalse(MetaTestHelper.MY_SUB_TYPE.isParentOf(MetaTestHelper.MY_TYPE))
    	assertTrue(MetaTestHelper.MY_TYPE.isParentOf(MetaTestHelper.MY_SUB_TYPE))
    }

    @Test
    public def void testCreate() {
    	val obj = MetaTestHelper.MY_TYPE.create
    	assertEquals(MyType, obj.class)
    }

    @Test
    public def void testRef() {
    	assertEquals(Meta.REF, Meta.HIERARCHY.findType(Ref))
    	assertEquals(Meta.REF, Meta.HIERARCHY.findType(Ref.name))
    }
}