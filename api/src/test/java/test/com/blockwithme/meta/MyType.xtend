package test.com.blockwithme.meta

import com.blockwithme.meta.Hierarchy
import com.blockwithme.meta.HierarchyBuilderFactory
import com.blockwithme.meta.JavaMeta
import com.blockwithme.meta.Kind
import com.blockwithme.meta.Type
import com.blockwithme.meta.beans.CollectionBean
import com.blockwithme.meta.beans.Meta
import com.blockwithme.meta.beans.impl.CollectionBeanImpl
import com.blockwithme.util.shared.converters.IntConverter

import static java.util.Objects.*
import com.blockwithme.meta.beans.CollectionBeanConfig
import com.blockwithme.meta.beans.impl._BeanImpl
import com.blockwithme.meta.beans.Bean
import test.com.blockwithme.MyBean
import com.blockwithme.util.shared.converters.IntConverterBase
import com.blockwithme.meta.beans.impl.MapBeanImpl

enum MyEnum {
  A,
  B,
  C
}

class EnumConverter extends IntConverterBase<Object,MyEnum> {

  new() {
  	super(MyEnum)
  }

  override fromObject(Object context, MyEnum obj) {
    if (!(requireNonNull(context, "context") instanceof MyType)) {
      throw new IllegalArgumentException("context should be a MyType, but is a "+context.class)
    }
    if(obj == null) -1 else obj.ordinal
  }

  override toObject(Object context, int value) {
    if (!(requireNonNull(context, "context") instanceof MyType)) {
      throw new IllegalArgumentException("context should be a MyType, but is a "+context.class)
    }
    if(value < 0) null else MyEnum.values.get(value)
  }

  public static val DEFAULT = new EnumConverter
}

/**
 * "package" visibility is required for the fields,
 * because the Properties are defined outside of MyType.
 *
 * And *that* is because Xtend does not support inner classes yet.
 *
 * But it's not all that bad; Java *automatically change private
 * fields to package fields when you use them in inner classes anyway*
 * (a rarely known fact, and an actual security issue!)
 */
class MyType {

  /** Boolean property */
  package var boolProp = false

  /** Byte property */
  package var byteProp = 0 as byte

  /** Short property */
  package var shortProp = 0 as short

  /** Char property */
  package var char charProp = ' '

  /** Int property */
  package var intProp = 0

  /** Long property */
  package var longProp = 0L

  /** Float property */
  package var floatProp = 0.0f

  /** Double property */
  package var doubleProp = 0.0

  /** Object property */
  package var objectProp = ""

  /** Non-Wrapper Integer Property, externally represented as a MyEnum */
  package var enumProp = 0
}

class MySubType extends MyType {
    /** Int property */
    package var intProp2 = 0
}

class MyBeanImpl extends _BeanImpl implements MyBean {
	new() {
		super(TestMyBeanMeta.MY_BEAN_TYPE)
	}
	override MyBean copy() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	override MyBean snapshot() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	override MyBean wrapper() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
}


class TestMyBeanMeta {
  /** Test Hierarchy Builder */
  public static val BUILDER = HierarchyBuilderFactory.getHierarchyBuilder(MyBean.name)

  public static val MY_BEAN_TYPE = BUILDER.newType(MyBean, null, Kind::Implementation, null, null)

  /** The test.com.blockwithme.meta package */
  public static val MY_PACKAGE = BUILDER.newTypePackage(MY_BEAN_TYPE)

  /** Test Hierarchy */
  public static val TEST = BUILDER.newHierarchy(newArrayList(MY_PACKAGE))
}

class MyCollectionType {
  /** unorderedSet CollectionBean Property*/
  package var unorderedSet = new CollectionBeanImpl<String>(
  	Meta.COLLECTION_BEAN, JavaMeta.STRING, CollectionBeanConfig.UNORDERED_SET)

  /** orderedSet CollectionBean Property*/
  package var orderedSet = new CollectionBeanImpl<String>(
  	Meta.COLLECTION_BEAN, JavaMeta.STRING, CollectionBeanConfig.ORDERED_SET)

  /** sortedSet CollectionBean Property*/
  package var sortedSet = new CollectionBeanImpl<String>(
  	Meta.COLLECTION_BEAN, JavaMeta.STRING, CollectionBeanConfig.SORTED_SET)

  /** hashSet CollectionBean Property*/
  package var hashSet = new CollectionBeanImpl<String>(
  	Meta.COLLECTION_BEAN, JavaMeta.STRING, CollectionBeanConfig.HASH_SET)

  /** list CollectionBean Property*/
  package var list = new CollectionBeanImpl<String>(
  	Meta.COLLECTION_BEAN, JavaMeta.STRING, CollectionBeanConfig.LIST)

  /** fixedSize list CollectionBean Property*/
  package var fixedSizeList = new CollectionBeanImpl<String>(
  	Meta.COLLECTION_BEAN, JavaMeta.STRING, CollectionBeanConfig.newFixedSizeList(10,true))

  /** Bean list CollectionBean Property*/
  package var beanList = new CollectionBeanImpl<MyBean>(
  	Meta.COLLECTION_BEAN, TestMyBeanMeta.MY_BEAN_TYPE, CollectionBeanConfig.LIST)
}

class MyMapType {
  /** MapBean Property*/
  package var map = new MapBeanImpl<String,Long>(Meta.MAP_BEAN, JavaMeta.STRING, false, JavaMeta.LONG, false)
}

class TestMeta {
  /** Test Hierarchy Builder */
  public static val BUILDER = HierarchyBuilderFactory.getHierarchyBuilder(MyType.name)

  public static val ENUM_TYPE = BUILDER.newType(MyEnum, null, Kind::Data, null, null)


  public static val BOOL_PROP = BUILDER.newBooleanProperty(
    MyType, "boolProp",
    [boolProp], [obj,value|obj.boolProp = value;obj], false
  )

  public static val BYTE_PROP = BUILDER.newByteProperty(
    MyType, "byteProp",
    [byteProp], [obj,value|obj.byteProp = value;obj], false
  )

  public static val CHAR_PROP = BUILDER.newCharacterProperty(
    MyType, "charProp",
    [charProp], [obj,value|obj.charProp = value;obj], false
  )

  public static val SHORT_PROP = BUILDER.newShortProperty(
    MyType, "shortProp",
    [shortProp], [obj,value|obj.shortProp = value;obj], false
  )

  public static val INT_PROP = BUILDER.newIntegerProperty(
    MyType, "intProp",
    [intProp], [obj,value|obj.intProp = value;obj], false
  )

  public static val LONG_PROP = BUILDER.newLongProperty(
    MyType, "longProp",
    [longProp], [obj,value|obj.longProp = value;obj], false
  )

  public static val FLOAT_PROP = BUILDER.newFloatProperty(
    MyType, "floatProp",
    [floatProp], [obj,value|obj.floatProp = value;obj], false
  )

  public static val DOUBLE_PROP = BUILDER.newDoubleProperty(
    MyType, "doubleProp",
    [doubleProp], [obj,value|obj.doubleProp = value;obj], false
  )

  public static val OBJECT_PROP = BUILDER.newObjectProperty(
    MyType, "objectProp",
    String, true, true, true,
    [objectProp], [obj,value|obj.objectProp = value;obj], false
  )

  public static val ENUM_PROP = BUILDER.newIntegerProperty(
    MyType, "enumProp",
    // Why does "EnumConverter.DEFAULT as IntConverter<MyType,MyEnum>" not compile *in Java*?
    EnumConverter.DEFAULT as IntConverter as IntConverter<MyType,MyEnum>, 32,
    MyEnum,
    [enumProp], [obj,value|obj.enumProp = value;obj], false
  )

  public static val INT_PROP2 = BUILDER.newIntegerProperty(
    MySubType, "intProp2",
    [intProp2], [obj,value|obj.intProp2 = value;obj], false
  )

  public static val VIRTUAL_BOOL_PROP = BUILDER.newBooleanProperty(
    MyType, "virtualBoolProp",
    [boolProp], [obj,value|obj.boolProp = value;obj], true
  )

  public static val META_PROP = Hierarchy.postCreateMetaProperty(
      com.blockwithme.meta.Meta.BUILDER.newMetaProperty(
        com.blockwithme.meta.Meta.TYPE, "persistent", Boolean, Boolean.FALSE, false))

  public static val Type<MyType> MY_TYPE = BUILDER.newType(MyType,
    [|new MyType], Kind.Implementation, null, null, BOOL_PROP, BYTE_PROP,
      CHAR_PROP, SHORT_PROP, INT_PROP, LONG_PROP, FLOAT_PROP,
      DOUBLE_PROP, OBJECT_PROP, ENUM_PROP, VIRTUAL_BOOL_PROP)

  public static val Type<MySubType> MY_SUB_TYPE
    = BUILDER.newType(MySubType, [|new MySubType],
      Kind.Implementation, null, null, #[MY_TYPE], INT_PROP2)

  public static val UNORDERED_SET_PROP = BUILDER.newObjectProperty(
    MyCollectionType, "unorderedSet",
    CollectionBean, true, true, true,
    [unorderedSet], [obj,value|obj.unorderedSet = value;obj], false)

  public static val ORDERED_SET_PROP = BUILDER.newObjectProperty(
    MyCollectionType, "orderedSet",
    CollectionBean, true, true, true,
    [orderedSet], [obj,value|obj.orderedSet = value;obj], false)

  public static val SORTED_SET_PROP = BUILDER.newObjectProperty(
    MyCollectionType, "sortedSet",
    CollectionBean, true, true, true,
    [sortedSet], [obj,value|obj.sortedSet = value;obj], false)

  public static val LIST_PROP = BUILDER.newObjectProperty(
    MyCollectionType, "list",
    CollectionBean, true, true, true,
    [list], [obj,value|obj.list = value;obj], false)

  public static val FIXED_SIZE_LIST_PROP = BUILDER.newObjectProperty(
    MyCollectionType, "fixedSizeList",
    CollectionBean, true, true, true,
    [fixedSizeList], [obj,value|obj.fixedSizeList = value;obj], false)

  public static val Type<MyCollectionType> MY_COLLECTION_TYPE
    = BUILDER.newType(MyCollectionType, [|new MyCollectionType],
      Kind.Implementation, null, null, UNORDERED_SET_PROP, ORDERED_SET_PROP,
      	SORTED_SET_PROP, LIST_PROP, FIXED_SIZE_LIST_PROP)

  /** The test.com.blockwithme.meta package */
  public static val MY_PACKAGE = BUILDER.newTypePackage(
    MY_TYPE, ENUM_TYPE, MY_SUB_TYPE, MY_COLLECTION_TYPE)

  public static val Type<Object> OBJECT2 = BUILDER.newType(Object, null, Kind.Data, null, null)

  /** The java.lang "other" package */
  public static val MY_JAVA_LANG = BUILDER.newTypePackage(
    OBJECT2)

  /** Test Hierarchy */
  public static val TEST = BUILDER.newHierarchy(
    newArrayList(MY_PACKAGE, MY_JAVA_LANG)
  )
}
