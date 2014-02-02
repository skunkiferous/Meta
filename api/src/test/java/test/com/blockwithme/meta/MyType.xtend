package test.com.blockwithme.meta

import com.blockwithme.meta.Hierarchy
import com.blockwithme.meta.HierarchyBuilder
import com.blockwithme.meta.JavaMeta
import com.blockwithme.meta.Kind
import com.blockwithme.meta.MetaMeta
import com.blockwithme.meta.MetaProperty
import com.blockwithme.meta.Type
import com.blockwithme.meta.TypePackage
import com.blockwithme.meta.converter.IntConverter

import static java.util.Objects.*

enum MyEnum {
  A,
  B,
  C
}

class EnumConverter implements IntConverter<Object,MyEnum> {

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

  override bits() {
    32
  }

  override type() {
    MyEnum
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

class TestMeta {
  /** Test Hierarchy Builder */
  public static val BUILDER = new HierarchyBuilder(MyType)

  public static val ENUM_TYPE = BUILDER.newType(MyEnum, null, Kind::Data)


  public static val BOOL_PROP = BUILDER.newBooleanProperty(
    MyType, "boolProp",
    [boolProp], [obj,value|obj.boolProp = value;obj]
  )

  public static val BYTE_PROP = BUILDER.newByteProperty(
    MyType, "byteProp",
    [byteProp], [obj,value|obj.byteProp = value;obj]
  )

  public static val CHAR_PROP = BUILDER.newCharacterProperty(
    MyType, "charProp",
    [charProp], [obj,value|obj.charProp = value;obj]
  )

  public static val SHORT_PROP = BUILDER.newShortProperty(
    MyType, "shortProp",
    [shortProp], [obj,value|obj.shortProp = value;obj]
  )

  public static val INT_PROP = BUILDER.newIntegerProperty(
    MyType, "intProp",
    [intProp], [obj,value|obj.intProp = value;obj]
  )

  public static val LONG_PROP = BUILDER.newLongProperty(
    MyType, "longProp",
    [longProp], [obj,value|obj.longProp = value;obj]
  )

  public static val FLOAT_PROP = BUILDER.newFloatProperty(
    MyType, "floatProp",
    [floatProp], [obj,value|obj.floatProp = value;obj]
  )

  public static val DOUBLE_PROP = BUILDER.newDoubleProperty(
    MyType, "doubleProp",
    [doubleProp], [obj,value|obj.doubleProp = value;obj]
  )

  public static val OBJECT_PROP = BUILDER.newObjectProperty(
    MyType, "objectProp",
    String, true, true, true,
    [objectProp], [obj,value|obj.objectProp = value;obj]
  )

  public static val ENUM_PROP = BUILDER.newIntegerProperty(
    MyType, "enumProp",
    // Why does "EnumConverter.DEFAULT as IntConverter<MyType,MyEnum>" not compile *in Java*?
    EnumConverter.DEFAULT as IntConverter as IntConverter<MyType,MyEnum>, 32,
    MyEnum,
    [enumProp], [obj,value|obj.enumProp = value;obj]
  )

  public static val INT_PROP2 = BUILDER.newIntegerProperty(
    MySubType, "intProp2",
    [intProp2], [obj,value|obj.intProp2 = value;obj]
  )

    public static val META_PROP = Hierarchy.postCreateMetaProperty(
      MetaMeta.BUILDER.newMetaProperty(
        MetaMeta.TYPE, "persistent", Boolean, Boolean.FALSE))

  public static val Type<MyType> MY_TYPE = BUILDER.newType(MyType,
    null/*[new MyType]*/, Kind.Implementation, BOOL_PROP, BYTE_PROP,
      CHAR_PROP, SHORT_PROP, INT_PROP, LONG_PROP, FLOAT_PROP,
      DOUBLE_PROP, OBJECT_PROP, ENUM_PROP)

  public static val Type<MySubType> MY_SUB_TYPE
    = BUILDER.newType(MySubType, null /*[new MySubType]*/,
      Kind.Implementation, #[MY_TYPE], INT_PROP2)

  /** The test.com.blockwithme.meta package */
  public static val MY_PACKAGE = BUILDER.newTypePackage(
    MY_TYPE, ENUM_TYPE, MY_SUB_TYPE)

  public static val Type<Object> OBJECT2 = BUILDER.newType(Object, null, Kind.Data)

  /** The java.lang "other" package */
  public static val MY_JAVA_LANG = BUILDER.newTypePackage(
    OBJECT2)

  /** Test Hierarchy */
  public static val TEST = BUILDER.newHierarchy(
    newArrayList(MY_PACKAGE, MY_JAVA_LANG), JavaMeta.HIERARCHY
  )
}
