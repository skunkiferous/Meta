package test.com.blockwithme.meta

import com.blockwithme.meta.Hierarchy
import com.blockwithme.meta.Types
import com.blockwithme.meta.Type
import com.blockwithme.meta.MetaProperty
import com.blockwithme.meta.TrueBooleanProperty
import com.blockwithme.meta.TrueByteProperty
import com.blockwithme.meta.TrueCharacterProperty
import com.blockwithme.meta.TrueShortProperty
import com.blockwithme.meta.TrueIntegerProperty
import com.blockwithme.meta.TrueLongProperty
import com.blockwithme.meta.TrueFloatProperty
import com.blockwithme.meta.TrueDoubleProperty
import com.blockwithme.meta.ObjectProperty
import com.blockwithme.meta.Kind
import com.blockwithme.meta.converter.IntConverter
import com.blockwithme.meta.IntegerProperty
import com.blockwithme.meta.HierarchyBuilder
import com.blockwithme.meta.TypePackage
import static java.util.Objects.*

enum MyEnum {
  A,
  B,
  C
}

class MyHierarchyBuilder {

  /** Test Hierarchy Builder */
  public static val TEST_BUILDER = new HierarchyBuilder(MyType)

  public static val ENUM_TYPE = new Type<MyEnum>(MyHierarchyBuilder.TEST_BUILDER, MyEnum, null, Kind::Data)
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

  public static val BOOL_PROP = new TrueBooleanProperty<MyType>(
    MyHierarchyBuilder.TEST_BUILDER, MyType, "boolProp",
    [boolProp], [obj,value|obj.boolProp = value;obj]
  )

  public static val BYTE_PROP = new TrueByteProperty<MyType>(
    MyHierarchyBuilder.TEST_BUILDER, MyType, "byteProp",
    [byteProp], [obj,value|obj.byteProp = value;obj]
  )

  public static val CHAR_PROP = new TrueCharacterProperty<MyType>(
    MyHierarchyBuilder.TEST_BUILDER, MyType, "charProp",
    [charProp], [obj,value|obj.charProp = value;obj]
  )

  public static val SHORT_PROP = new TrueShortProperty<MyType>(
    MyHierarchyBuilder.TEST_BUILDER, MyType, "shortProp",
    [shortProp], [obj,value|obj.shortProp = value;obj]
  )

  public static val INT_PROP = new TrueIntegerProperty<MyType>(
    MyHierarchyBuilder.TEST_BUILDER, MyType, "intProp",
    [intProp], [obj,value|obj.intProp = value;obj]
  )

  public static val LONG_PROP = new TrueLongProperty<MyType>(
    MyHierarchyBuilder.TEST_BUILDER, MyType, "longProp",
    [longProp], [obj,value|obj.longProp = value;obj]
  )

  public static val FLOAT_PROP = new TrueFloatProperty<MyType>(
    MyHierarchyBuilder.TEST_BUILDER, MyType, "floatProp",
    [floatProp], [obj,value|obj.floatProp = value;obj]
  )

  public static val DOUBLE_PROP = new TrueDoubleProperty<MyType>(
    MyHierarchyBuilder.TEST_BUILDER, MyType, "doubleProp",
    [doubleProp], [obj,value|obj.doubleProp = value;obj]
  )

  public static val OBJECT_PROP = new ObjectProperty<MyType, String>(
    MyHierarchyBuilder.TEST_BUILDER, MyType, "objectProp",
    Types.STRING, true, true, true,
    [objectProp], [obj,value|obj.objectProp = value;obj]
  )

  public static val ENUM_PROP = new IntegerProperty<MyType, MyEnum, IntConverter<MyType, MyEnum>>(
    MyHierarchyBuilder.TEST_BUILDER, MyType, "enumProp",
    EnumConverter.DEFAULT as IntConverter, 32,
    MyHierarchyBuilder.ENUM_TYPE,
    [enumProp], [obj,value|obj.enumProp = value;obj]
  )
}

class MySubType extends MyType {

  /** Int property */
  package var intProp2 = 0

  public static val INT_PROP2 = new TrueIntegerProperty<MySubType>(
    MyHierarchyBuilder.TEST_BUILDER, MySubType, "intProp2",
    [intProp2], [obj,value|obj.intProp2 = value;obj]
  )

}

class MyHierarchy {
    public static val META_PROP = Hierarchy.postCreateMetaProperty(
      new MetaProperty<Type,Boolean>(Types.META_BUILDER,
        Types.TYPE, "persistent", Types.BOOLEAN, Boolean.FALSE))

  public static val Type<MyType> MY_TYPE = new Type(MyHierarchyBuilder.TEST_BUILDER, MyType,
    null/*[new MyType]*/, Kind.Implementation, MyType.BOOL_PROP, MyType.BYTE_PROP,
      MyType.CHAR_PROP, MyType.SHORT_PROP, MyType.INT_PROP, MyType.LONG_PROP, MyType.FLOAT_PROP,
      MyType.DOUBLE_PROP, MyType.OBJECT_PROP, MyType.ENUM_PROP)

  public static val Type<MySubType> MY_SUB_TYPE
    = new Type(MyHierarchyBuilder.TEST_BUILDER, MySubType, null /*[new MySubType]*/,
      Kind.Implementation, #[MY_TYPE], MySubType.INT_PROP2)

  /** The test.com.blockwithme.meta package */
  public static val MY_PACKAGE = new TypePackage(MyHierarchyBuilder.TEST_BUILDER,
    MY_TYPE, MyHierarchyBuilder.ENUM_TYPE, MY_SUB_TYPE)

  public static val Type<Object> OBJECT2 = new Type(MyHierarchyBuilder.TEST_BUILDER, Object, null, Kind.Data)

  /** The java.lang "other" package */
  public static val MY_JAVA_LANG = new TypePackage(MyHierarchyBuilder.TEST_BUILDER,
    OBJECT2)

  /** Test Hierarchy */
  public static val TEST = new Hierarchy(MyHierarchyBuilder.TEST_BUILDER,
    newArrayList(MY_PACKAGE, MY_JAVA_LANG), Types::JAVA
  )
}
