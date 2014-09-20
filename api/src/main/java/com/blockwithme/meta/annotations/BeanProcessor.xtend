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
package com.blockwithme.meta.annotations

import com.blockwithme.meta.BooleanProperty
import com.blockwithme.meta.BooleanPropertyAccessor
import com.blockwithme.meta.HierarchyBuilder
import com.blockwithme.meta.HierarchyBuilderFactory
import com.blockwithme.meta.JavaMeta
import com.blockwithme.meta.Kind
import com.blockwithme.meta.Type
import com.blockwithme.meta.TypePackage
import com.blockwithme.meta.beans.CollectionBeanConfig
import com.blockwithme.meta.beans.Entity
import com.blockwithme.meta.beans.ListBean
import com.blockwithme.meta.beans.MapBean
import com.blockwithme.meta.beans.Meta
import com.blockwithme.meta.beans.SetBean
import com.blockwithme.meta.beans.impl.CollectionBeanImpl
import com.blockwithme.meta.beans.impl.MapBeanImpl
import com.blockwithme.meta.beans.impl._BeanImpl
import com.blockwithme.meta.beans.impl._EntityImpl
import com.blockwithme.util.xtend.annotations.Processor
import com.blockwithme.util.xtend.annotations.ProcessorUtil
import java.lang.annotation.ElementType
import java.lang.annotation.Inherited
import java.lang.annotation.Retention
import java.lang.annotation.RetentionPolicy
import java.lang.annotation.Target
import java.util.ArrayList
import java.util.Collection
import java.util.HashMap
import java.util.HashSet
import java.util.List
import java.util.Map
import java.util.Objects
import java.util.Set
import javax.inject.Provider
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.RegisterGlobalsContext
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.AnnotationReference
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.EnumerationTypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MemberDeclaration
import org.eclipse.xtend.lib.macro.declaration.MethodDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableEnumerationTypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableFieldDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableInterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableTypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import org.eclipse.xtend.lib.macro.declaration.Visibility

import static java.util.Objects.*
import com.blockwithme.meta.ValidatorsMap
import com.blockwithme.meta.ListenersMap
import com.blockwithme.meta.BytePropertyRangeValidator
import com.blockwithme.meta.CharacterPropertyRangeValidator
import com.blockwithme.meta.ShortPropertyRangeValidator
import com.blockwithme.meta.IntegerPropertyRangeValidator
import com.blockwithme.meta.FloatPropertyRangeValidator
import com.blockwithme.meta.LongPropertyRangeValidator
import com.blockwithme.meta.DoublePropertyRangeValidator

/**
 * Specifies a Validator for a Property.
 *
 * The Validator is assumed to be thread-safe and will be instantiated
 * and used as part of the per-Type list of Validators for that Property.
 *
 * To make things simple, we use the "simple name" of the Property as Key,
 * and since the Validators are Property-Type-specific, we do not try to
 * check at compile time if they are of the right type.
 */
@Retention(RetentionPolicy.CLASS)
annotation ValidatorDef {
	/** The "simple" Property name within the annotated type */
	String property
	/**
	 * The class that implements the validator.
	 * Note that the required type depends on the exact property type;
	 * BooleanPropertyValidator, ...
	 */
	Class<?> type
}

/**
 * Specifies any number of Property Validators for a Bean.
 *
 * TODO New annotations validate @NN(not-null/not-negative)
 *
 * TODO We must be able to specify "exact type" for a Property, as this has an effect on serialization. It could be verified by the Validator.
 */
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.CLASS)
annotation Validators {
	ValidatorDef[] value
}

/**
 * Specifies a "range" for some Properties.
 *
 * The range is validated by instantiating an appropriate validator.
 */
@Target(ElementType.FIELD)
@Retention(RetentionPolicy.CLASS)
annotation Range {
	/**
	 * The (hard) minimum value.
	 *
	 * Leave empty to not have a minimum value.
	 *
	 * Breaking this limit will cause an exception to be thrown when setting the Property.
	 */
	String min = ""

	/**
	 * The (hard) maximum value.
	 *
	 * Leave empty to not have a maximum value.
	 *
	 * Breaking this limit will cause an exception to be thrown when setting the Property.
	 */
	String max = ""

	/**
	 * The soft minimum value.
	 *
	 * Leave empty to not have a soft minimum value.
	 *
	 * Breaking this limit will cause a warning to be logged when setting the Property.
	 */
	String softMin = ""

	/**
	 * The soft maximum value.
	 *
	 * Leave empty to not have a soft maximum value.
	 *
	 * Breaking this limit will cause a warning to be logged when setting the Property.
	 */
	String softMax = ""
}

/**
 * A ValidationException is thrown, when one or more validators
 * find problems with the new value of a Property.
 */
class ValidationException extends RuntimeException {
    new(String message) {
        super(message)
    }

    new(Throwable cause) {
        super(cause)
    }

    new(String message, Throwable cause) {
        super(message, cause)
    }
}

/**
 * Specifies a Listener for a Property.
 *
 * The Listener is assumed to be thread-safe and will be instantiated
 * and used as part of the per-Type list of Listeners for that Property.
 *
 * To make things simple, we use the "simple name" of the Property as Key,
 * and since the Listeners are Property-Type-specific, we do not try to
 * check at compile time if they are of the right type.
 *
 * TODO Until retro-fitting is available, it would be good to be able
 * to declare listeners or "other" types, for example a type you depend
 * on from a base project.
 */
@Retention(RetentionPolicy.CLASS)
annotation ListenerDef {
	/** The "simple" Property name within the annotated type */
	String property
	/**
	 * The class that implements the listener.
	 * Note that the required type depends on the exact property type;
	 * BooleanPropertyListener, ...
	 */
	Class<?> type
}

/**
 * Specifies any number of Property Listeners for a Bean.
 */
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.CLASS)
annotation Listeners {
	ListenerDef[] value
}

/**
 * Used on a Bean.Impl.method(parameter), to cause the generation
 * of variations on this method, by replacing the parameters
 * annotated with DefaultsTo, with the "value" of DefaultsTo.
 *
 * We'll assume that the use of DefaultsTo should not "create virtual Properties"
 *
 * @Generated is used to differentiate user-methods from generated ones.
 */
@Target(ElementType.PARAMETER)
@Retention(RetentionPolicy.CLASS)
annotation DefaultsTo {
	String value
}

/**
 * Annotates an interface declared in a C-style-struct syntax
 * into a full-blown bean, including, in particular, defining the type
 * and it's properties using the Meta API.
 *
 * @author monster
 */
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.CLASS)
@Inherited
@Active(MyActiveProc)
annotation Bean {
	boolean instance = false
	String[] sortKeyes = #[]
}

/**
 * The possible types of collection properties.
 *
 * TODO This type *should be an enum*, but some bug in Xtend prevent me from using an enum.
 * Since I cannot create a *simple* test-case that shows the bug, they just won't fix it. :(
 */
interface CollectionPropertyType {
	/** Are we an unordered set? */
	val unorderedSet = "unorderedSet"
	/** Are we an ordered set? */
	val orderedSet = "orderedSet"
	/** Are we a sorted set? */
	val sortedSet = "sortedSet"
	/** Are we a hash set? */
	val hashSet = "hashSet"
	/** Are we a list? */
	val list = "list"
}

/**
 * Annotates a property field as an unordered set collection type.
 * Can only be applied to arrays.
 *
 * @author monster
 */
@Target(ElementType.FIELD)
@Retention(RetentionPolicy.CLASS)
annotation UnorderedSetProperty {
}

/**
 * Annotates a property field as an ordered set collection type.
 * Can only be applied to arrays.
 *
 * @author monster
 */
@Target(ElementType.FIELD)
@Retention(RetentionPolicy.CLASS)
annotation OrderedSetProperty {
}

/**
 * Annotates a property field as a sorted set collection type.
 * Can only be applied to arrays.
 *
 * Note that unordered-sets are *more efficient*, and are still sorted when
 * getContent() is called (non-comparable types might not "look" sorted).
 *
 * @author monster
 */
@Target(ElementType.FIELD)
@Retention(RetentionPolicy.CLASS)
annotation SortedSetProperty {
}

/**
 * Annotates a property field as an hash set collection type.
 * Can only be applied to arrays.
 *
 * @author monster
 */
@Target(ElementType.FIELD)
@Retention(RetentionPolicy.CLASS)
annotation HashSetProperty {
}

/**
 * Annotates a property field as a list collection type.
 * Can only be applied to arrays.
 *
 * @author monster
 */
@Target(ElementType.FIELD)
@Retention(RetentionPolicy.CLASS)
annotation ListProperty {
	int fixedSize = -1
	boolean nullAllowed = false
}

@Data
package class PropertyInfo {
  String name
  String type
  String comment
  /*CollectionPropertyType*/String colType
  int fixedSize
  boolean nullAllowed
  /** Virtual Property? Then the implementation is generated as part of the "Impl methods" */
  boolean virtualProp
  String min
  String max
  String softMin
  String softMax
}

@Data
package class InnerImpl {
  String qualifiedName
  Map<String,String> declarationToClass
  new (String qualifiedName) {
  	_qualifiedName = Objects.requireNonNull(qualifiedName, "qualifiedName")
  	_declarationToClass = new HashMap
  	_hasInit = new ArrayList
  }
  List<String> hasInit
}

@Data
package class BeanInfo {
  String qualifiedName
  BeanInfo[] parents
  List<PropertyInfo> properties
  List<String> validity
  boolean isBean
  boolean isInstance
  String[] sortKeyes
  InnerImpl innerImpl
  def pkgName() {
  	val index = qualifiedName.lastIndexOf('.')
    if (index < 0)
    	""
	else
    	qualifiedName.substring(0,index)
  }
  def simpleName() {
  	val index = qualifiedName.lastIndexOf('.')
    if (index < 0)
    	qualifiedName
	else
    	qualifiedName.substring(index+1)
  }
  // STEP 22
  // If we have more then one parent, find out all missing properties
  def Map<String,PropertyInfo[]> allProperties() {
    val result = new HashMap<String,PropertyInfo[]>
    for (p : properties) {
      requireNonNull(p, qualifiedName+".properties[?]")
    }
    result.put(qualifiedName, properties)
    for (p : parents) {
      result.putAll(p.allProperties)
    }
    result
  }
  def Set<String> allParents() {
    val result = new HashSet<String>
    allParents(result)
    result
  }
  private def void allParents(HashSet<String> result) {
    if (result.add(qualifiedName)) {
      for (p : parents) {
        p.allParents(result)
      }
    }
  }
  /** Check the BeanInfo is fully initialized */
  public def void check() {
    requireNonNull(qualifiedName, "qualifiedName")
    requireNonNull(allProperties, "allProperties")
    requireNonNull(parents, "parents")
    requireNonNull(properties, "properties")
    for (p : parents) {
      requireNonNull(p, "parents[?]")
    }
    for (p : properties) {
      requireNonNull(p, "properties[?]")
      requireNonNull(p.name, "properties[?].name")
      requireNonNull(p.type, "properties[?].type")
    }
    for (p : validity) {
      requireNonNull(p, "validity[?]")
    }
  }
}

/**
 * Stores in the class-file the BeanInfo data
 */
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.CLASS)
annotation _BeanInfo {
    Class<?>[] parents = #[]
    String[] properties = #[] //name0,type0,comment0,colType0,fixedSize0,nullAllowed0,getterJavaCode0,setterJavaCode0...
    String[] validity = #[]
	String[] sortKeyes = #[]
    boolean isBean
    boolean isInstance
    String[] innerImpl
}

/**
 * Stores in the implementation class-file the directly implemented interface
 */
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.CLASS)
annotation BeanImplemented {
    Class<?> implemented
}

/**
 * Process classes annotated with @Bean
 *
 * REGISTER:
 * 0) Type must be an interface
 * 1) For each type, scan the type hierarchy, recording field names and types along the way
 * 2) Each Type in the hierarchy must either contain only fields without initializers, or be one of the Base types (Bean or Entity)
 * 3) No (case insensitive) "simple" type name must be used more then once within Hierarchy+dependencies.
 * 4) No (case insensitive) "simple" field name must be used more then once within Hierarchy+dependencies.
 * 5) For each type, an Impl type under impl package is registered, if not defined yet
 * 6) For each type, a type Provider under impl package is registered, if not defined yet
 * 7) For each type *package*, a Meta interface is declared, if not defined yet
 * 8) For each type property (including the virtual ones), an Accessor type under impl package is declared, if not defined yet
 * GENERATE:
 * 9) For each type, the fields are replaced with getters and setters
 * 10) Type.Impl.(static,public)_init_(Type) method is used as a pseudo-constructor, if present.
 * 10.1) DefaultsTo annotated Type.Impl.(static,public)method(Type[,...]) are "defaulted"
 * 11) For every Type.Impl.(static,public)method(Type[,...]), a method without the Type parameter is declared in Type
 * 12) Extract virtual properties from the optional Impl class
 * 13) A builder is created in Meta for that package
 * 14) For each type property, a property accessor class is generated
 * 15) For each type property, a property object in the "Meta" interface is generated.
 * 16) For each type, a type Provider under impl package is generated.
 * 16.1) For each type, the declared Listeners and Validators (including Range validation) are extracted.
 * 17) For each type, following the properties, a type instance is created.
 * 18) After all types, a package meta-object is created.
 * 19) The list of dependencies for the Hierarchy is computed.
 * 20) The Impl extends either the impl of the first parent, or BaseImpl or EntityImpl appropriately
 * 21) For all getters and setters in type, implementations are generated in Impl
 * 22) If we have more then one parent, find out all missing properties
 * 23) For all imported methods from the Type.Impl, delegators are generated in Impl
 * 24) Generate implementations for all missing properties in Impl
 * 25) Add BeanImplemented annotation to the implementation class.
 * 26) Make sure "instance" Beans have all their abstract methods implemented.
 * 27) Implementation class should have comments too.
 * 28) Comments should be generated for Meta too
 * 29) Comments should be generated for the accessors.
 * 30) Add non-beans immutable types to Meta, so they can be used as properties
 * 31) Comments on properties must be transfered to generated code
 * 32) Comments should be generated for the providers.
 * 33) Comments should be generated for the implementation fields.
 * 34) @_BeanInfo must be generated on the type
 * 35) Make sure inheritance works across file boundaries
 * 36) Type should extend Bean
 * 37) Generate the "copy methods" in the Type
 * 38) Generate the "copy methods" in the implementation
 * 39) Optionally extend Comparable in Type
 * 40) Generate optional compareTo() method in implementation
 *
 * TODO: Review the whole code, adding comments, and fixing log-levels
 *
 * WARNING: Always specify explicitly the *return type* of extension methods!
 *
 * @author monster
 */
class BeanProcessor extends Processor<TypeDeclaration,MutableTypeDeclaration> {
  static val char DOT = '.'
  static val NO_PARENTS = <BeanInfo>newArrayOfSize(0)
  static val NO_PROPERTIES = <PropertyInfo>newArrayOfSize(0)
  static val DUPLICATE = 'Duplicate simple name'
  static val BEAN_QUALIFIED_NAME = com.blockwithme.meta.beans.Bean.name
  static val ENTITY_QUALIFIED_NAME = Entity.name
  static val String BEAN_KEY = cacheKey(BEAN_QUALIFIED_NAME)
  static val String ENTITY_KEY = cacheKey(ENTITY_QUALIFIED_NAME)
  static val BP_HIERARCHY_ROOT = "BP_HIERARCHY_ROOT"
  static val BP_NON_BEAN_TODO = "BP_NON_BEAN_TODO"
  static val INIT = "_init_()"
  static val BEAN_FILTER = and(isInterface,withAnnotation(Bean))
  static val PROP_INFO_FIELDS = 11

  /** Returns true, if the type is/should be a Bean */
  private def boolean isBean(org.eclipse.xtend.lib.macro.declaration.Type type) {
  	val beanIntf = findTypeGlobally(com.blockwithme.meta.beans.Bean)
  	if (beanIntf.isAssignableFrom(type)) {
  		return true
  	}
  	if (type instanceof TypeDeclaration) {
	  	val beanAnn = findTypeGlobally(Bean)
	  	if (type.findAnnotation(beanAnn) != null) {
	  		return true
	  	}
  	}
  	false
  }

  /** Public constructor for this class. */
  new() {
    // Step 0, make sure we have an interface, annotated with @Bean
    // Or it's an immutable type (not modified, but at least registered)
    super(or(isEnum,withAnnotation(Data),BEAN_FILTER))
  }

  /** Converts CamelCase to CAMEL_CASE */
  private static def String cameCaseToSnakeCase(String camelCase) {
    camelCase.replaceAll(
      String.format("%s|%s|%s",
        "(?<=[A-Z])(?=[A-Z][a-z])",
        "(?<=[^A-Z_])(?=[A-Z])",
        "(?<=[A-Za-z])(?=[^A-Za-z_])"
      ),
      "_"
    ).toUpperCase;
  }

  /** Capitalizes the first letter of a property name, taking "_" into account */
  private static def String propertyToXetterSuffix(String property) {
    if (property.startsWith("_"))
    	// Do NOT capitalize the first letter, if property starts with _
    	// Otherwise, we have to type person._Age instead of person._age
    	"_"+property.substring(1)
	else
		property.toFirstUpper
  }

  /** Returns the Provider name */
  private def providerName(String pkgName, String simpleName) {
    pkgName+'.impl.'+simpleName+'Provider'
  }

  /** Returns the Property Accessor name */
  private def propertyAccessorName(String pkgName, String simpleName, String property) {
    val name = if (property.startsWith('_')) '_'+simpleName else simpleName
    val to_FirstUpper = if (property.startsWith("_"))
    	"_"+(property.substring(1)).toFirstUpper
	else
		property.toFirstUpper
    pkgName+'.impl.'+name+to_FirstUpper+'Accessor'
  }

  /** Returns the implementation name */
  private def implName(String pkgName, String simpleName) {
    pkgName+'.impl.'+simpleName+'Impl'
  }

  /** Returns the meta name */
  private def metaName(String pkgName) {
    pkgName+'.Meta'
  }

  /** *Safely* registers an interface */
  private def registerInterface(InterfaceDeclaration td, RegisterGlobalsContext context, String name) {
    setShouldBeInterface(name)
    try {
      context.registerInterface(name)
      warn(BeanProcessor, "register", td, "Registering Interface: "+name)
    } catch(IllegalArgumentException ex) {
      // NOP (already registered)
    }
  }

  /** *Safely* registers a class */
  private def registerClass(InterfaceDeclaration td, RegisterGlobalsContext context, String name) {
    try {
      context.registerClass(name)
      warn(BeanProcessor, "register", td, "Registering Class: "+name)
    } catch(IllegalArgumentException ex) {
      // NOP (already registered)
    }
  }

  /** Returns false if the given type name is not valid for a property */
  private def validPropertyType(Map<String,Object> processingContext, TypeReference typeRef, TypeDeclaration parent) {
    if (typeRef.array || typeRef.primitive || typeRef.wrapper
      || (typeRef == string) || (typeRef == classTypeRef)) {
      return true
    }
    val name = ProcessorUtil.qualifiedName(typeRef)
    val start = name.indexOf('<')
    val nameNoGen = if (start < 0) name else name.substring(0, start)
    // Collections can also be defined the old-fashioned way.
    if (("java.util.List" == nameNoGen) || ("java.util.Set" == nameNoGen) || ("java.util.Map" == nameNoGen)) {
    	return true
    }
  	val allTypes = processingContext.get(PC_ALL_FILE_TYPES) as List<TypeDeclaration>
    var org.eclipse.xtend.lib.macro.declaration.Type type = allTypes.findFirst[it.qualifiedName == nameNoGen]
    if (type === null) {
	    type = findTypeGlobally(nameNoGen)
	    if (isBean(type)) {
	      return true
	    }
    } else if (isBean(type)) {
      return true
    }
    if (type instanceof TypeDeclaration) {
      val bi = beanInfo(processingContext, type)
      if ((bi !== null) && bi.validity.empty) {
        return true
      }
	    val enumType = findTypeGlobally(Enum)
    	if (enumType.isAssignableFrom(type) || (type instanceof EnumerationTypeDeclaration)) {
    		// Enum == Immutable!
    		return true
    	}
    	// TODO Stop using @Data because *we cannot persist it*. Once done, update BeanVisitable and BeanVisitor.
	    val dataAnnot = findTypeGlobally(Data)
    	if (type.findAnnotation(dataAnnot) !== null) {
    		// @Data == Immutable!
    		return true
    	}
    }
    if (type === null) {
    	error(BeanProcessor, "validPropertyType", null, "Could not resolve type "+name)
    } else {
    	var parents = "?"
    	var annotations = "?"
    	if (type instanceof TypeDeclaration) {
    		parents = ProcessorUtil.qualifiedNames(findParents(type))
    		annotations = type.annotations.map[it.annotationTypeDeclaration.qualifiedName].reduce[p1, p2|p1+","+p2]
    	}
    	error(BeanProcessor, "validPropertyType", null,
    		"Type "+name+" is NOT a Bean, or comes *after* the using type "+parent.qualifiedName
    		+": parents="+parents+" annotations="+annotations)
    }
    false
  }

  private static def cacheKey(String qualifiedName) {
    "BeanInfo:"+qualifiedName
  }

  private static def noSameSimpleNameKey(String simpleName) {
    "noSameSimpleNameKey:"+simpleName.toLowerCase
  }

  private def putInCache(Map<String,Object> processingContext, String key, String noSameSimpleNameKey, BeanInfo beanInfo) {
    requireNonNull(beanInfo, "beanInfo")
    processingContext.put(key, beanInfo)
    var list = processingContext.get(noSameSimpleNameKey) as List<BeanInfo>
    if (list === null) {
      list = newArrayList()
      processingContext.put(noSameSimpleNameKey, list)
      list.add(beanInfo)
    } else {
      list.add(beanInfo)
      // STEP 3 (we do not change the validity of pre-exiting, now-invalid, types
      val validity = beanInfo.validity
      if (!validity.contains(DUPLICATE)) {
        validity.add(DUPLICATE)
      }
    }
    debug(BeanProcessor, "putInCache", null, "Adding BeanInfo("+beanInfo.qualifiedName+","
      +beanInfo.parents.map[it?.qualifiedName]+") to cache")
  }

  private def BeanInfo beanInfo(Map<String,Object> processingContext, String qualifiedName) {
  	var plainQualifiedName = qualifiedName
  	val index = plainQualifiedName.indexOf('<')
  	if (index > 0) {
  		plainQualifiedName = plainQualifiedName.substring(0,index)
  	}
    val td = findTypeGlobally(plainQualifiedName)
    if (td === null) {
      // Unknown/undefined type (too early to query?)
      val result = new BeanInfo(plainQualifiedName,NO_PARENTS,NO_PROPERTIES,
        newArrayList("Undefined: "+plainQualifiedName), false, false, #[], null)
      result.check()
      val key = cacheKey(plainQualifiedName)
      val simpleName = plainQualifiedName.substring(plainQualifiedName.lastIndexOf(DOT)+1)
      val noSameSimpleNameKey = noSameSimpleNameKey(simpleName)
      putInCache(processingContext, key, noSameSimpleNameKey, result)
      return result
    }
    if (td instanceof TypeDeclaration) {
    	return beanInfo(processingContext, td)
	}
	  // Primitive type!
	  val result = new BeanInfo(plainQualifiedName,NO_PARENTS,NO_PROPERTIES,
	    newArrayList(), false, false, #[], null)
	  result.check()
	  val key = cacheKey(plainQualifiedName)
	  val simpleName = plainQualifiedName.substring(plainQualifiedName.lastIndexOf(DOT)+1)
	  val noSameSimpleNameKey = noSameSimpleNameKey(simpleName)
	  putInCache(processingContext, key, noSameSimpleNameKey, result)
	  return result
  }

  /** Returns the property creation method name */
  private def String wrapperOrObject(String typeName) {
    switch (typeName) {
      case "void": "java.lang.Void"
      case "boolean": "java.lang.Boolean"
      case "byte": "java.lang.Byte"
      case "char": "java.lang.Character"
      case "short": "java.lang.Short"
      case "int": "java.lang.Integer"
      case "float": "java.lang.Float"
      case "long": "java.lang.Long"
      case "double": "java.lang.Double"
      default: typeName
    }
  }

  private static def isMap(PropertyInfo propInfo) {
  	propInfo.type.startsWith(MapBean.name+"<")
  }

  private static def isCol(PropertyInfo propInfo) {
  	propInfo.type.startsWith(ListBean.name+"<") || propInfo.type.startsWith(SetBean.name+"<")
  }

  /** Extract virtual properties from the optional Impl class */
  private def void extractVirtualProperties(Map<String,Object> processingContext, BeanInfo result,
  	TypeDeclaration td, ClassDeclaration innerImplClass, ArrayList<PropertyInfo> properties,
  	int fields, HashMap<String,MethodDeclaration> xetterInnerMethods, Collection<String> parentFields) {
  	val list = new ArrayList<PropertyInfo>
  	if ((innerImplClass != null) && !xetterInnerMethods.empty) {
	    val qualifiedName = innerImplClass.qualifiedName
	    var index = fields
  		for (e : xetterInnerMethods.entrySet) {
  			val m = e.value
  			val decl = m.simpleName
  			if (decl.startsWith("get")) {
  				val name = m.simpleName.substring(3).toFirstLower
	        	val ftype = m.returnType
				if (ftype == null) {
					throw new NullPointerException(
						qualifiedName+"."+m.simpleName+".type: null"
					)
				}
			    if (!parentFields.contains(name.toLowerCase)) {
		        	beanInfoField(processingContext, result, td, properties, index, m, ftype, name, true)
				    index = index + 1
			    }
  			}
  		}
  	}
  	list.toArray(newArrayOfSize(list.size))
  }

	// STEP 10.1
	// DefaultsTo annotated Type.Impl.(static,public)method(Type[,...]) are "defaulted"
	private def void preDefineDefaultedMethods(Map<String,Object> processingContext,
		TypeDeclaration td, ClassDeclaration innerImplClass,
		HashMap<String,String> ownInnerMethods, MethodDeclaration m) {
		// TODO
	}

  // STEP 1/2
  private def BeanInfo beanInfo(Map<String,Object> processingContext, TypeDeclaration td) {
    // Lazy init
    if (!processingContext.containsKey(BEAN_KEY)) {
      val b = new BeanInfo(BEAN_QUALIFIED_NAME,NO_PARENTS,NO_PROPERTIES, newArrayList(), true, false, #[], null)
      b.check()
      processingContext.put(BEAN_KEY, b)
      val bi = new BeanInfo(ENTITY_QUALIFIED_NAME,newArrayList(b),NO_PROPERTIES, newArrayList(), true, false, #[], null)
      bi.check()
      processingContext.put(ENTITY_KEY, bi)
    }
    val qualifiedName = td.qualifiedName
    val simpleName = td.simpleName
    val pkgName = qualifiedName.substring(0, qualifiedName.lastIndexOf(DOT))
    val key = cacheKey(qualifiedName)
    val noSameSimpleNameKey = noSameSimpleNameKey(simpleName)
    var result = processingContext.get(key) as BeanInfo
    if (result === null) {
      val bean = td.findAnnotation(findTypeGlobally(Bean))
      val isAccepted = BEAN_FILTER.apply(processingContext, processorUtil,td)
	  val isInstance = (bean !== null) && bean.getBooleanValue("instance")
        val filePkg = (processingContext.get(Processor.PC_PACKAGE) as String)
        // OK, this type comes from a *dependency*
        if (filePkg != pkgName) {
          val _beanInfo = td.findAnnotation(findTypeGlobally(_BeanInfo))
          if (_beanInfo !== null) {
            // and it was already processed, so we can extract the BeanInfo from
            // a *generated* annotations
            result = extractBeanInfo(processingContext, qualifiedName, _beanInfo)
            result.check()
            putInCache(processingContext, key, noSameSimpleNameKey, result)
            return result
          }
       }
//      val check = checkIsBeanOrMarker(processingContext, td)
	  val check = if (td instanceof InterfaceDeclaration)
	  	null
  	  else
  	    td.qualifiedName
      if (check !== null) {
        // not valid as Bean/Marker type
        var msg = "Non Bean/Marker type: "+qualifiedName
        if (qualifiedName != check) {
          msg = msg + " because of "+check
        }
        result = new BeanInfo(qualifiedName,NO_PARENTS,NO_PROPERTIES,
          newArrayList(msg), false, isInstance, #[], null)
        result.check()
        putInCache(processingContext, key, noSameSimpleNameKey, result)
      } else {
        // Could be OK type ...
	    val String[] sortKeyes = if (bean !== null) bean.getStringArrayValue("sortKeyes") else #[]
        val parentsTD = findDirectParents(td)
        val fields = td.declaredFields
        val innerImplName = qualifiedName+".Impl"
		val innerImpl = new InnerImpl(innerImplName)
		val innerImplClass = td.declaredClasses.findFirst[it.qualifiedName==innerImplName]

		// STEP 11
		val ownInnerMethods = new HashMap<String,String>
		val xetterInnerMethods = new HashMap<String,MethodDeclaration>
		if (innerImplClass != null) {
			for (m : innerImplClass.declaredMethods) {
				val declaration = innerMethodToString(td, m);
				if (declaration != null) {
					ownInnerMethods.put(declaration, innerImplName)
					if ((m.simpleName.length > 3) && declaration.startsWith("get") && m.parameters.tail.empty) {
						xetterInnerMethods.put(declaration, m)
					}
					// STEP 10.1
					preDefineDefaultedMethods(processingContext, td, innerImplClass,
						ownInnerMethods, m)
				}
			}
		}

        // Add early in cache, to prevent infinite loops
        val parents = <BeanInfo>newArrayOfSize(parentsTD.size)
        val properties = new ArrayList<PropertyInfo>

        result = new BeanInfo(qualifiedName,parents,properties,
          newArrayList(), isAccepted, isInstance, sortKeyes, innerImpl)
        putInCache(processingContext, key, noSameSimpleNameKey, result)
        // Find parents
        var index = 0
        val parentFields = new HashSet<String>()
        for (p : parentsTD) {
          val b = beanInfo(processingContext, p)
          parents.set(index, b)
          index = index + 1
          if (!b.validity.isEmpty) {
            result.validity.add("Parent "+p.qualifiedName+" is not valid")
          }
          for (pa : b.allProperties.values) {
	          for (pp : pa) {
	            requireNonNull(pp, b.qualifiedName+".properties[?]")
	            requireNonNull(pp.name, b.qualifiedName+".properties[?].name")
	            parentFields.add(pp.name.toLowerCase)
	          }
          }
        }

		// STEP 10
		// Type.Impl.(static,public)_init_(Type) method is used as a pseudo-constructor, if present.
		if (ownInnerMethods.remove(INIT) != null) {
			innerImpl.hasInit.add(innerImplName)
		}

		// STEP 11
		val innerMethods = new HashMap<String,String>
        for (p : parentsTD) {
            val parentInnerImpl = beanInfo(processingContext, p).innerImpl
            if (parentInnerImpl != null) {
            	for (e : parentInnerImpl.declarationToClass.entrySet) {
            		val m = e.key
            		if (!ownInnerMethods.containsKey(m)) {
            			val declaringType = e.value
            			// Method from parent inner Impl that is not overridden
            			val current = innerMethods.get(m)
            			if ((current != null) && (current != declaringType)) {
            				result.validity.add("Method "+m+" is not defined by "
            					+innerImplName+" but by parent "+p.qualifiedName
            					+" AND OTHER(S): conflict!")
            			} else {
            				innerMethods.put(m, declaringType)
            			}
            		}
            	}
				// STEP 10
				// TODO That probably won't give us the right initialization order
            	for (hi : parentInnerImpl.hasInit) {
            		if (!innerImpl.hasInit.contains(hi)) {
            			innerImpl.hasInit.add(hi)
            		}
            	}
            }
        }
        innerMethods.putAll(ownInnerMethods)
        innerImpl.declarationToClass.putAll(innerMethods)

        // Find properties
        index = 0
        for (f : fields) {
        	val ftype = f.type
			if (ftype == null) {
				throw new NullPointerException(
					qualifiedName+"."+f.simpleName+".type: null, isAccepted: "+isAccepted+", check: "+check
				)
			}
        	beanInfoField(processingContext, result, td, properties, index, f, ftype, f.simpleName, false)
		  // STEP 4
		  // This does NOT apply to virtual properties
		  if (parentFields.contains(f.simpleName.toLowerCase)) {
		    result.validity.add("Property(Field) "+f.simpleName
		      +" is a duplicate from a parent property")
		  }
		  index = index + 1
        }
        // STEP 12
        // Extract virtual properties from the optional Impl class
        extractVirtualProperties(processingContext, result,
  			td, innerImplClass, properties, index, xetterInnerMethods, parentFields)

        val allProps = result.allProperties.values
        for (sortKey : sortKeyes) {
        	var found = false
        	for (array : allProps) {
        		if (array.exists[name == sortKey]) {
        			found = true
        		}
        	}
        	if (!found) {
            	result.validity.add("sortKey "+sortKey+" not found in properties")
        	}
        }
        result.check()
        debug(BeanProcessor, "putInCache", null, "Updating BeanInfo("+qualifiedName+","
          +result.parents.map[it?.qualifiedName]+") in cache")
      }
    }
    if (result !== null) {
      result.check()
    }
    result
  }

  private def void beanInfoField(Map<String,Object> processingContext, BeanInfo result,
  	TypeDeclaration td, ArrayList<PropertyInfo> properties, int index, MemberDeclaration f,
  	TypeReference ftype, String simpleName, boolean virtualProp) {
  		val qualifiedName = td.qualifiedName
	  val ftypeName = ftype.name
	  val start = ftypeName.indexOf('<')
	  val nameNoGen = if (start < 0) ftypeName else ftypeName.substring(0, start)
	  // Collections can also be defined the old-fashioned way.
	  val oldStyleCol = (("java.util.List" == nameNoGen) || ("java.util.Set" == nameNoGen))
	  val isMap = ("java.util.Map" == nameNoGen)
	  val doc = if (f.docComment === null) "" else f.docComment
	  val unorderedSetAnnot = f.findAnnotation(findTypeGlobally(UnorderedSetProperty))
	  val orderedSetAnnot = f.findAnnotation(findTypeGlobally(OrderedSetProperty))
	  val sortedSetAnnot = f.findAnnotation(findTypeGlobally(SortedSetProperty))
	  val hashSetAnnot = f.findAnnotation(findTypeGlobally(HashSetProperty))
	  val listAnnot = f.findAnnotation(findTypeGlobally(ListProperty))
	  val isCollProp = (unorderedSetAnnot !== null) || (orderedSetAnnot !== null)
	  	|| (sortedSetAnnot !== null) || (hashSetAnnot !== null) || (listAnnot !== null)
	  while (properties.size <= index) {
	  	properties.add(null)
	  }
	  // Read optional Range annotation and store it so a Validator can be created automatically
	  	var min = ""
	  	var max = ""
	  	var softMin = ""
	  	var softMax = ""
	  val rangeAnn = f.findAnnotation(findTypeGlobally(Range))
	  if (rangeAnn !== null) {
	  	min = rangeAnn.getStringValue("min")
	  	max = rangeAnn.getStringValue("max")
	  	softMin = rangeAnn.getStringValue("softMin")
	  	softMax = rangeAnn.getStringValue("softMax")
	  }
	  if (ftype.array || oldStyleCol) {
	  	// A collection property!
	  	val componentTypeName0 = if (oldStyleCol) {
	  		ftypeName.substring(start+1, ftypeName.length - 1)
		} else {
	      	ftype.arrayComponentType.name
	  	}
	  	val componentTypeName = wrapperOrObject(componentTypeName0)
	  	var String collType = null
	  	var fixedSize = -1
	  	var nullAllowed = false
	  	if (isCollProp) {
	  		if (oldStyleCol) {
	  				throw new IllegalStateException(
	  					"'old-style' collection types do not support collection annotations on "
	  					+qualifiedName+"."+simpleName)
	  		}
	  		if (unorderedSetAnnot !== null) {
	  			collType = CollectionPropertyType.unorderedSet
	  		}
	  		if (orderedSetAnnot !== null) {
	  			if (collType !== null) {
	  				throw new IllegalStateException(
	  					"Multiple collection types used on "+qualifiedName+"."+simpleName)
	  			}
	  			collType = CollectionPropertyType.orderedSet
	  		}
	  		if (sortedSetAnnot !== null) {
	  			if (collType !== null) {
	  				throw new IllegalStateException(
	  					"Multiple collection types used on "+qualifiedName+"."+simpleName)
	  			}
	  			collType = CollectionPropertyType.sortedSet
	  		}
	  		if (hashSetAnnot !== null) {
	  			if (collType !== null) {
	  				throw new IllegalStateException(
	  					"Multiple collection types used on "+qualifiedName+"."+simpleName)
	  			}
	  			collType = CollectionPropertyType.hashSet
	  		}
	  		if (listAnnot !== null) {
	  			if (collType !== null) {
	  				throw new IllegalStateException(
	  					"Multiple collection types used on "+qualifiedName+"."+simpleName)
	  			}
	  			collType = CollectionPropertyType.list
	  			fixedSize = listAnnot.getIntValue("fixedSize")
	  			nullAllowed = listAnnot.getBooleanValue("nullAllowed")
			}
		} else if (oldStyleCol) {
			collType = if ("java.util.List" == nameNoGen)
				CollectionPropertyType.list
			else
				CollectionPropertyType.unorderedSet
	  	} else {
			collType = CollectionPropertyType.unorderedSet
	  	}
	  	val String typeName = if (CollectionPropertyType.list == collType)
	  		ListBean.name+"<"+componentTypeName+">"
		else
	  		SetBean.name+"<"+componentTypeName+">"
	    properties.set(index, new PropertyInfo(
	        requireNonNull(simpleName, "f.simpleName"),
	        requireNonNull(typeName, "typeName"), doc, collType, fixedSize,
	        nullAllowed, virtualProp, min, max, softMin, softMax))
	  } else if (isMap) {
	  	// A Map property!
	  	val String typeName = MapBean.name+ftypeName.substring(start)
	    properties.set(index, new PropertyInfo(
	        requireNonNull(simpleName, "f.simpleName"),
	        requireNonNull(typeName, "typeName"), doc, null, -1,
	        true, virtualProp, min, max, softMin, softMax))
	  } else {
	  	  if (isCollProp) {
	  		// NOT a collection property!
	        result.validity.add("Property "+simpleName+" is not a collection type (must be array)")
	  	  }
	      properties.set(index, new PropertyInfo(
	        requireNonNull(simpleName, "f.simpleName"),
	        requireNonNull(ftypeName, "ftypeName"),
	        doc, null, -1, false, virtualProp, min, max, softMin, softMax))
	  }
	  if (!validPropertyType(processingContext, ftype, td)) {
	    result.validity.add("Property "+simpleName+" is not valid")
	  }
  }

  /** Adds Getters and Setter to the Bean Interface. */
  def private void processField(MutableFieldDeclaration fieldDeclaration,
      MutableInterfaceDeclaration interf) {
    val fieldName = fieldDeclaration.simpleName
    val toFirstUpper = propertyToXetterSuffix(fieldName)
    val fieldType = fieldDeclaration.type
    val start = fieldType.name.indexOf('<')
    val nameNoGen = if (start < 0) fieldType.name else fieldType.name.substring(0, start)
    // Collections can also be defined the old-fashioned way.
    val oldStyleCol = (("java.util.List" == nameNoGen) || ("java.util.Set" == nameNoGen))
    val isMap = ("java.util.Map" == nameNoGen)
    val propertyType = if (fieldType.array) {
    	val componentType = fieldType.arrayComponentType
      	val listAnnot = fieldDeclaration.findAnnotation(findTypeGlobally(ListProperty))
      	if (listAnnot === null)
    		newTypeReference(SetBean, componentType)
		else
    		newTypeReference(ListBean, componentType)
    } else if (oldStyleCol) {
    	val componentType = fieldType.actualTypeArguments.get(0)
    	if ("java.util.List" == nameNoGen)
    		newTypeReference(ListBean, componentType)
		else
    		newTypeReference(SetBean, componentType)
    } else if (isMap) {
    	val actualTypeArguments = fieldType.actualTypeArguments
    	newTypeReference(MapBean, actualTypeArguments.get(0), actualTypeArguments.get(1))
    } else
    	fieldType
    val doc = if (fieldDeclaration.docComment != null) fieldDeclaration.docComment else "";

    val getter = 'get' + toFirstUpper
    if (interf.findDeclaredMethod(getter) === null) {
      onMethodAdded(interf.addMethod(getter) [
        returnType = propertyType
        // STEP 31
        // Comments on properties must be transfered to generated code
        if (doc.empty) {
          docComment = "Getter for "+fieldName
        } else {
          docComment = "Getter for "+doc
        }
      ])
      warn(BeanProcessor, "transform", interf, "Adding "+getter+" to "+interf.qualifiedName)
    }
    val setter = 'set' + toFirstUpper
    if (interf.findDeclaredMethod(setter, propertyType) === null) {
      onMethodAdded(interf.addMethod(setter) [
        addParameter(fieldName, propertyType)
        returnType = interf.newTypeReference
        // STEP 31
        // Comments on properties must be transfered to generated code
        if (fieldType.array || oldStyleCol || isMap) {
	        if (doc.empty) {
	          docComment = "Setter (accepts only null!) for "+fieldName
	        } else {
	          docComment = "Setter (accepts only null!) for "+doc
	        }
        } else {
	        if (doc.empty) {
	          docComment = "Setter for "+fieldName
	        } else {
	          docComment = "Setter for "+doc
	        }
        }
      ])
      warn(BeanProcessor, "transform", interf, "Adding " + setter+" to "+interf.qualifiedName)
    }
    if (fieldType.array || oldStyleCol || isMap) {
	    val getter2 = 'getRaw' + toFirstUpper
	    if (interf.findDeclaredMethod(getter2) === null) {
	      onMethodAdded(interf.addMethod(getter2) [
	        returnType = propertyType
	        // STEP 31
	        // Comments on properties must be transfered to generated code
	        if (doc.empty) {
	          docComment = "Raw Getter for "+fieldName
	        } else {
	          docComment = "Raw Getter for "+doc
	        }
	      ])
	      warn(BeanProcessor, "transform", interf, "Adding "+getter2+" to "+interf.qualifiedName)
	    }
    }
    warn(BeanProcessor, "transform", interf, "Removing "+fieldName+" from "+interf.qualifiedName)
    fieldDeclaration.remove()
  }

    /** Concerts an inner Impl method to a declaration String, if the method qualifies */
    def private String innerMethodToString(TypeDeclaration td, MethodDeclaration m) {
		innerMethodToString(td.qualifiedName, m)
    }

    /** Concerts an inner Impl method to a declaration String, if the method qualifies */
    def private String innerMethodToString(String qualifiedName, MethodDeclaration m) {
		if (m.static && (m.visibility == Visibility.PUBLIC) && (m.parameters.head?.type?.name == qualifiedName)) {
			val buf = new StringBuffer
			buf.append(m.simpleName)
			if (m.parameters.length == 1) {
				buf.append("()")
			} else {
				var sep = "("
				for (p : m.parameters.tail) {
					buf.append(sep)
					sep = ","
					buf.append(removeGeneric(p.type.name))
				}
			}
			return buf.toString
		}
    	null
    }

	/** Import methods from Type.Impl. */
	def private importInnerImplIntoInterface(MutableInterfaceDeclaration mtd, BeanInfo beanInfo) {
		// STEP 11
		val innerImpl = beanInfo.innerImpl
		if ((innerImpl != null) && !innerImpl.declarationToClass.empty) {
			// Must be public static ...
			val innerImplClass = mtd.declaredClasses.findFirst[qualifiedName==innerImpl.qualifiedName]
			if (innerImplClass != null) {
  				warn(BeanProcessor, "transform", mtd, "findAllMethods("+mtd.qualifiedName+") "
  					+ mtd.findAllMethods().map[declaringType.qualifiedName+'.'+signature]
  				)
  				// STEP 10.1
  				// TODO First, actually add the defaulted methods to innerImplClass
  				// And if this does not cause innerImplClass.declaredMethods to be
  				// updated, then add them explicitly in the interface too
				for (m : innerImplClass.declaredMethods) {
					val key = innerMethodToString(mtd, m)
					if (innerImpl.declarationToClass.containsKey(key)) {
						val params = m.parameters.tail
						var TypeReference[] paramTypes = newArrayOfSize(params.size)
						paramTypes = params.map[type].toList.toArray(paramTypes)
						val dup = mtd.findMethod(m.simpleName, paramTypes)
						if ((dup === null) || (m.returnType != dup.returnType)) {
							onMethodAdded(mtd.addMethod(m.simpleName) [
								for (p : params) {
						        	addParameter(p.simpleName, p.type)
					        	}
						        returnType = m.returnType
						        docComment = m.docComment
							])
		      				warn(BeanProcessor, "transform", mtd, "Adding(Impl) " + m.simpleName+" to "+mtd.qualifiedName)
	      				}
					}
				}
			}
		}
    }

    /** Returns the BeanInfo of the *parent* of a Class, if any */
    private def BeanInfo findParentBeanInfo(Map<String,Object> processingContext, MutableClassDeclaration impl) {
		if (impl.extendedClass?.type instanceof ClassDeclaration) {
			val pt = impl.extendedClass.type as ClassDeclaration
			val beanImplAnn = findTypeGlobally(BeanImplemented)
			val beanImpl = pt?.findAnnotation(beanImplAnn)
			val implemented = beanImpl?.getClassValue("implemented")
			val parentImplementedInerfaceName = implemented?.name
			if (parentImplementedInerfaceName != null) {
				return beanInfo(processingContext, parentImplementedInerfaceName)
			}
		}
		null
    }

	/** For all imported methods from the Type.Impl, delegators are generated in Impl */
	private def void importInnerImplIntoImpl(Map<String,Object> processingContext,
		MutableInterfaceDeclaration intf, MutableClassDeclaration impl, BeanInfo beanInfo) {
		val innerImpl = beanInfo.innerImpl
		if ((innerImpl == null) || innerImpl.declarationToClass.empty) {
			return
		}
		// TODO All the "defaulted" methods from STEP 10.1 must also be imported here
		val parentImplMethods = new HashMap<String,String>
		val piBI = findParentBeanInfo(processingContext, impl)
		if ((piBI != null) && (piBI.innerImpl != null)) {
			parentImplMethods.putAll(piBI.innerImpl.declarationToClass)
		}
		val myImplMethods = new HashMap<String,String>(innerImpl.declarationToClass)
		for (e : parentImplMethods.entrySet) {
			val m = myImplMethods.get(e.key)
			if (m == e.value) {
				myImplMethods.remove(e.key)
			}
		}
		if (myImplMethods.empty) {
			return
		}
		val declImplToMethods = new HashMap<String,Iterable<? extends MethodDeclaration>>
		val nameToMethod = new HashMap<String,MethodDeclaration>
		val qualifiedName = impl.qualifiedName
		val dotImplLen = ".Impl".length
		for (e : myImplMethods.entrySet) {
			val methodDecl = e.key
			val declImplName = e.value
			var declMethods = declImplToMethods.get(declImplName)
			if (declMethods == null) {
				val decl = findTypeGlobally(declImplName)
				declMethods = (decl as ClassDeclaration).declaredMethods
				declImplToMethods.put(declImplName, declMethods.filter[!parameters.empty])
			}
			val intfName = declImplName.substring(0,declImplName.length - dotImplLen)
			for (m : declMethods) {
				if (methodDecl == innerMethodToString(intfName, m)) {
					nameToMethod.put(methodDecl, m)
				}
			}
			if (nameToMethod.get(methodDecl) == null) {
  				error(BeanProcessor, "importInnerImplIntoImpl", intf,
  					"Could not find "+methodDecl+" for "+qualifiedName)
			}
		}
		for (e : nameToMethod.entrySet) {
			val methodDecl = e.key
			val m = e.value
			var TypeReference[] paramTypes = newArrayOfSize(m.parameters.size)
			paramTypes = m.parameters.map[type].toList.toArray(paramTypes)
			val dup = impl.findDeclaredMethod(m.simpleName, paramTypes)
			if (dup === null) {
				val bodyText = new StringBuffer
				if (!m.returnType.void) {
					bodyText.append("return ")
				}
				bodyText.append(myImplMethods.get(methodDecl)).append(".")
				bodyText.append(m.simpleName).append("(this")
				onMethodAdded(impl.addMethod(m.simpleName) [
					for (p : m.parameters.tail) {
			        	addParameter(p.simpleName, p.type)
			        	bodyText.append(",").append(p.simpleName)
		        	}
		        	bodyText.append(");")
		        	visibility = Visibility.PUBLIC
		        	static = false
		        	abstract = false
		        	// We always allow overriding
		        	final = false
			        returnType = m.returnType
			        docComment = m.docComment
			        body = [bodyText]
				])
  				warn(BeanProcessor, "transform", intf, "Adding " + m.simpleName+" to "+qualifiedName)
			} else {
				// Possibly due to incremental compilation?
  				error(BeanProcessor, "transform", intf, "Could not add method " + m.simpleName+" to "+qualifiedName)
			}
		}
	}

  /** Returns the name of the hierarchy root of this interface. */
  private def String getHierarchyRoot(TypeDeclaration mtd) {
	val bean = findTypeGlobally(Bean)
	val todo = <TypeDeclaration>newArrayList(findParents(mtd))
	val done = <TypeDeclaration>newArrayList()
	val roots = <TypeDeclaration>newArrayList()
	while (!todo.empty) {
		val last = todo.remove(todo.size - 1)
		done.add(last)
		var parentHasGotIt = false
		val parents = findParents(last).iterator
		while (parents.hasNext && !parentHasGotIt) {
			val p = parents.next
			if ((p !== last) && (p.findAnnotation(bean) !== null)) {
				parentHasGotIt = true
			}
		}
		if (!parentHasGotIt && (last.findAnnotation(bean) !== null)) {
			roots.add(last)
		}
	}
	if (roots.size > 1) {
	  error(BeanProcessor, "transform", mtd,
			"Multiple parents of " + mtd.qualifiedName + " have the Bean annotation: " +
				ProcessorUtil.qualifiedNames(roots as Iterable<?>))
	}
	roots.get(0).qualifiedName
  }

  /** Adds the builder field */
  private def void addBuilderField(MutableInterfaceDeclaration meta, TypeDeclaration mtd,
    Map<String,Object> processingContext) {
    val hierarchyRoot = getHierarchyRoot(mtd)
    if (hierarchyRoot === null) {
      error(BeanProcessor, "transform", mtd, "Hierarchy Root of "+mtd.qualifiedName+" is null!")
    // Only define once!
    } else if (meta.findDeclaredField("BUILDER") === null) {
      // public static final BUILDER = HierarchyBuilderFactory.registerHierarchyBuilder("hierarchyRoot");
      meta.addField("BUILDER") [
        visibility = Visibility.PUBLIC
        final = true
        static = true
        type = newTypeReference(HierarchyBuilder)
        initializer = [
          '''«HierarchyBuilderFactory.name».getHierarchyBuilder("«hierarchyRoot»")'''
        ]
        docComment = "BUILDER field for the Hierarchy of this Package"
      ]
      processingContext.put(BP_HIERARCHY_ROOT, hierarchyRoot)
      warn(BeanProcessor, "transform", mtd, "Adding BUILDER to "+meta.qualifiedName)

      // First time we use Meta, so give is a comment:
      // STEP 28
      // Comments should be generated for Meta too
      meta.setDocComment("The Class Meta contains constants defining meta-information about types of this package.")

      // STEP 30
		var delayedNonBeans = processingContext.get(BP_NON_BEAN_TODO) as ArrayList<TypeDeclaration>
		if (delayedNonBeans !== null) {
			processingContext.remove(BP_NON_BEAN_TODO)
			for (type : delayedNonBeans) {
				addTypeField(type, meta, beanInfo(processingContext, type), "")
			}
		}
    } else {
      val currentRoot = processingContext.get(BP_HIERARCHY_ROOT)
      if ((currentRoot !==null) && (hierarchyRoot != currentRoot)) {
        error(BeanProcessor, "transform", mtd,
          "Multiple hierarchy roots used in the same package (at least "
          +currentRoot+" and "+hierarchyRoot+")")
      }
    }
  }

  /** Build the accessor interface name */
  private def String propertyAccessorPrefix(String propType) {
    // Make accessor extend <Type>PropertyAccessor
    switch (propType) {
      case "boolean": "Boolean"
      case "byte": "Byte"
      case "char": "Char"
      case "short": "Short"
      case "int": "Int"
      case "float": "Float"
      case "long": "Long"
      case "double": "Double"
      default: "Object"
    }
  }

  /** Build the accessor interface name */
  private def String acessorInterfaceName(String propertyAccessorPrefix) {
    val pkg = BooleanPropertyAccessor.package.name
    pkg+'.'+propertyAccessorPrefix+"PropertyAccessor"
  }

  /** Implements the required Property accessor interface */
  private def String implementPropertyAccessor(BeanInfo beanInfo, PropertyInfo propInfo) {
    warn(BeanProcessor, "transform", findTypeGlobally(beanInfo.qualifiedName),
      "Implementing BUILDER to "+beanInfo.qualifiedName)
    val pkgName = beanInfo.pkgName
    val simpleName = beanInfo.simpleName
    val qualifiedName = beanInfo.qualifiedName
    val accessorName = propertyAccessorName(pkgName, simpleName, propInfo.name)
    val accessor = getClass(accessorName)
    val propType = propInfo.type
    val propTypeRef = newTypeReferenceWithGenerics(propType)
    // Make accessor extend <Type>PropertyAccessor
    val propertyAccessorPrefix = propertyAccessorPrefix(propType)
    val acessorInterfaceName = acessorInterfaceName(propertyAccessorPrefix)
    val typeName = qualifiedName
    val beanType = newTypeReference(typeName)
    val typeRef = if ("Object" == propertyAccessorPrefix) #[beanType, propTypeRef] else #[beanType]
    val propertyAccessorIntf = newTypeReference(acessorInterfaceName, typeRef)
    accessor.setImplementedInterfaces(newArrayList(propertyAccessorIntf))
    accessor.visibility = Visibility.PUBLIC
    accessor.final = true
    // Add getter
    val instanceType = beanType
    if (accessor.findDeclaredMethod("apply", instanceType) === null) {
      val bodyText = '''return instance.get«propertyToXetterSuffix(propInfo.name)»();'''
      onMethodAdded(accessor.addMethod("apply") [
        visibility = Visibility.PUBLIC
        final = true
        static = false
        returnType = propTypeRef
        addParameter("instance", instanceType)
        body = [
          bodyText
        ]
        docComment = "Getter for the property "+qualifiedName+"."+propInfo.name
      ])
    }
    // Add setter
    val valueType = propTypeRef
    if (accessor.findDeclaredMethod("apply", instanceType, valueType) === null) {
      val bodyText = '''return instance.set«propertyToXetterSuffix(propInfo.name)»(newValue);'''
      onMethodAdded(accessor.addMethod("apply") [
        visibility = Visibility.PUBLIC
        final = true
        static = false
        returnType = instanceType
        addParameter("instance", instanceType)
        addParameter("newValue", valueType)
        body = [
          bodyText
        ]
        docComment = "Setter for the property "+qualifiedName+"."+propInfo.name
      ])
    }
    // STEP 29
    // Comments should be generated for the accessors.
    accessor.setDocComment("Accessor for the property "+qualifiedName+"."+propInfo.name)
    accessorName
  }

  /** Returns the property creation method name */
  private def String propertyMethodName(PropertyInfo propInfo) {
    switch (propInfo.type) {
      case "boolean": "BooleanProperty"
      case "byte": "ByteProperty"
      case "char": "CharacterProperty"
      case "short": "ShortProperty"
      case "int": "IntegerProperty"
      case "float": "FloatProperty"
      case "long": "LongProperty"
      case "double": "DoubleProperty"
      default: "ObjectProperty"
    }
  }

  /** Returns the property field name */
  private def String getPropertyFieldNameInMeta(String simpleName, PropertyInfo propInfo) {
    cameCaseToSnakeCase(simpleName)+"__"+cameCaseToSnakeCase(propInfo.name)
  }

  /** Creates a Property constant in meta */
  private def String createPropertyConstant(MutableInterfaceDeclaration intf,
    MutableInterfaceDeclaration meta, BeanInfo beanInfo, String accessorName, PropertyInfo propInfo) {
    val metaPkg = BooleanProperty.package.name
    val propName = propertyMethodName(propInfo)
    val name = getPropertyFieldNameInMeta(beanInfo.simpleName, propInfo)
    val isVirtual = propInfo.virtualProp
    if (meta.findDeclaredField(name) === null) {
      val simpleName = beanInfo.simpleName
      val qualifiedName = beanInfo.qualifiedName
      val beanType = newTypeReference(qualifiedName)
      val TypeReference retTypeRef = if ("ObjectProperty" == propName) {
  		val objType = newTypeReferenceWithGenerics(propInfo.type)
        newTypeReference(metaPkg+"."+propName, beanType, objType, objType, newWildcardTypeReference())
      } else {
        newTypeReference(metaPkg+".True"+propName, beanType)
      }
      warn(BeanProcessor, "transform", intf, "Adding "+name+" to "+meta.qualifiedName)
      val init = if ("ObjectProperty" == propName) {
      	// We drop the generic part
      	var propTypeName = propInfo.type
      	val index = propTypeName.indexOf("<")
      	if (index > 0) {
      		propTypeName = propTypeName.substring(0, index)
      	}
        // TODO Work out the real value for the boolean flags!
        '''BUILDER.new«propName»(«simpleName».class, "«propInfo.name»", «propTypeName».class,
        true, true, false, new «accessorName»(), «isVirtual»)'''
      } else {
        '''BUILDER.new«propName»(«simpleName».class, "«propInfo.name»", new «accessorName»(), «isVirtual»)'''
      }
      meta.addField(name) [
        visibility = Visibility.PUBLIC
        final = true
        static = true
        type = retTypeRef
        initializer = [
          init
        ]
        // SETP 28
        // Comments should be generated for Meta too
        docComment = "Property field for "+beanInfo.qualifiedName+"."+propInfo.name
      ]
    }
    name
  }

  /** Crate a Provider for a type */
  private def void createProvider(MutableInterfaceDeclaration intf, BeanInfo beanInfo) {
    val pkgName = beanInfo.pkgName
    val simpleName = beanInfo.simpleName
    val providerName = providerName(pkgName, simpleName)
    val provider = getClass(providerName)
    warn(BeanProcessor, "transform", intf, "Implementing "+providerName)
    val beanType = newTypeReference(beanInfo.qualifiedName)
    val providerIntf = newTypeReference(Provider, beanType)
    provider.setImplementedInterfaces(newArrayList(providerIntf))
    provider.visibility = Visibility.PUBLIC
    provider.final = true
    if (provider.findDeclaredMethod("get") === null) {
      val bodyText = '''return new «implName(pkgName, simpleName)»();'''
      onMethodAdded(provider.addMethod("get") [
        visibility = Visibility.PUBLIC
        final = true
        static = false
        returnType = newTypeReference(beanInfo.qualifiedName)
        body = [
          bodyText
        ]
        // STEP 32
        // Comments should be generated for the providers.
        docComment = "Creates and returns a new "+beanInfo.qualifiedName
      ])
    }
    // STEP 32
    // Comments should be generated for the providers.
    provider.docComment = "Provider for the type "+beanInfo.qualifiedName
  }

  /** Returns the code pointing to a Type instance, for the given BeanInfo */
  private def String beanInfoToTypeCode(BeanInfo beanInfo, String localPackage) {
    if (beanInfo.isBean || (beanInfo.pkgName == localPackage)) {
      beanInfo.pkgName+".Meta."+cameCaseToSnakeCase(beanInfo.simpleName)
    } else {
      val java = JavaMeta.HIERARCHY.findType(beanInfo.qualifiedName)
      if (java !== null) {
        JavaMeta.name+"."+cameCaseToSnakeCase(java.simpleName)
	  } else {
	      val meta = Meta.HIERARCHY.findType(beanInfo.qualifiedName)
	      if (meta !== null) {
	        Meta.name+"."+cameCaseToSnakeCase(meta.simpleName)
		  } else {
	      	null
	      }
      }
    }
  }

  /** Generates an appropriate Validator instantiation */
  private def String genValidatorFor(PropertyInfo propInfo) {
  	var min = ""
  	var max = ""
  	var softMin = ""
  	var softMax = ""
  	var type = ""

  	val _min = propInfo.min
  	val _max = propInfo.max
  	val _softMin = propInfo.softMin
  	val _softMax = propInfo.softMax

  	if (propInfo.type == "byte") {
	  	min = "java.lang.Byte.MIN_VALUE"
	  	max = "java.lang.Byte.MAX_VALUE"
	  	softMin = min
	  	softMax = max
	  	if (_min != "") {
	  		min = _min
	  	}
	  	if (_max != "") {
	  		max = _max
	  	}
	  	if (_softMin != "") {
	  		softMin = _softMin
	  	}
	  	if (_softMax != "") {
	  		softMax = _softMax
	  	}
  		type = BytePropertyRangeValidator.name
  	} else if (propInfo.type == "char") {
	  	min = "java.lang.Character.MIN_VALUE"
	  	max = "java.lang.Character.MAX_VALUE"
	  	softMin = min
	  	softMax = max
	  	if (_min != "") {
	  		min = _min
	  	}
	  	if (_max != "") {
	  		max = _max
	  	}
	  	if (_softMin != "") {
	  		softMin = _softMin
	  	}
	  	if (_softMax != "") {
	  		softMax = _softMax
	  	}
  		type = CharacterPropertyRangeValidator.name
  	} else if (propInfo.type == "short") {
	  	min = "java.lang.Short.MIN_VALUE"
	  	max = "java.lang.Short.MAX_VALUE"
	  	softMin = min
	  	softMax = max
	  	if (_min != "") {
	  		min = _min
	  	}
	  	if (_max != "") {
	  		max = _max
	  	}
	  	if (_softMin != "") {
	  		softMin = _softMin
	  	}
	  	if (_softMax != "") {
	  		softMax = _softMax
	  	}
  		type = ShortPropertyRangeValidator.name
  	} else if (propInfo.type == "int") {
	  	min = "java.lang.Integer.MIN_VALUE"
	  	max = "java.lang.Integer.MAX_VALUE"
	  	softMin = min
	  	softMax = max
	  	if (_min != "") {
	  		min = _min
	  	}
	  	if (_max != "") {
	  		max = _max
	  	}
	  	if (_softMin != "") {
	  		softMin = _softMin
	  	}
	  	if (_softMax != "") {
	  		softMax = _softMax
	  	}
  		type = IntegerPropertyRangeValidator.name
  	} else if (propInfo.type == "long") {
	  	min = "java.lang.Long.MIN_VALUE"
	  	max = "java.lang.Long.MAX_VALUE"
	  	softMin = min
	  	softMax = max
	  	if (_min != "") {
	  		min = _min
	  	}
	  	if (_max != "") {
	  		max = _max
	  	}
	  	if (_softMin != "") {
	  		softMin = _softMin
	  	}
	  	if (_softMax != "") {
	  		softMax = _softMax
	  	}
  		type = LongPropertyRangeValidator.name
  	} else if (propInfo.type == "double") {
	  	min = "java.lang.Double.MIN_VALUE"
	  	max = "java.lang.Double.MAX_VALUE"
	  	softMin = min
	  	softMax = max
	  	if (_min != "") {
	  		min = _min
	  	}
	  	if (_max != "") {
	  		max = _max
	  	}
	  	if (_softMin != "") {
	  		softMin = _softMin
	  	}
	  	if (_softMax != "") {
	  		softMax = _softMax
	  	}
  		type = DoublePropertyRangeValidator.name
  	}
  	if (type == "") {
  		throw new IllegalStateException("Does not know how to create validator for "+propInfo.type)
  	}
  	type+"("+min+","+max+","+softMin+","+softMax+")"
  }

   /** Finds and returns the Validators, if any. */
   private def String findPropertyValidators(TypeDeclaration intf, BeanInfo beanInfo) {
	   	val ranges = beanInfo.properties.filter[(min!=""||max!=""||softMin!=""||softMax!="")].iterator
	  	val validatorsAnn = intf.findAnnotation(findTypeGlobally(Validators))
	  	if ((validatorsAnn !== null) || ranges.hasNext) {
		   	val buf = new StringBuilder('''new «ValidatorsMap.name»()''')
		   	if (validatorsAnn !== null) {
		  		for (a : validatorsAnn.getAnnotationArrayValue("value")) {
		  			val propName = a.getStringValue("property")
		  			if ((propName !== null) && !propName.empty) {
			  			val type = a.getClassValue("type")
			  			if (type !== null) {
				  			buf.append('.add("').append(propName).append('", new ')
				  				.append(type.name).append("())")
		  				} else {
					    	error(BeanProcessor, "transform", intf, intf.qualifiedName+": "
					    		+ValidatorDef.name+".type cannot be null")
		  				}
		  			} else {
				    	error(BeanProcessor, "transform", intf, intf.qualifiedName+": "
				    		+ValidatorDef.name+".property cannot be null or empty")
			    	}
		  		}
	  		}
	  		while (ranges.hasNext) {
	  			val r = ranges.next
	  			val propName = r.name
	  			buf.append('.add("').append(propName).append('", new ').append(genValidatorFor(r)).append(")")
	  		}
		   	buf.toString
	  	} else {
	  		"null"
	  	}
   }

   /** Finds and returns the Listeners, if any. */
   private def String findPropertyListeners(TypeDeclaration intf, BeanInfo beanInfo) {
	  	val listenersAnn = intf.findAnnotation(findTypeGlobally(Listeners))
	  	if (listenersAnn !== null) {
		   	val buf = new StringBuilder('''new «ListenersMap.name»()''')
	  		for (a : listenersAnn.getAnnotationArrayValue("value")) {
	  			val propName = a.getStringValue("property")
	  			if ((propName !== null) && !propName.empty) {
		  			val type = a.getClassValue("type")
		  			if (type !== null) {
			  			buf.append('.add("').append(propName).append('", new ')
			  				.append(type.name).append("())")
	  				} else {
				    	error(BeanProcessor, "transform", intf, intf.qualifiedName+": "
				    		+ValidatorDef.name+".type cannot be null")
	  				}
	  			} else {
			    	error(BeanProcessor, "transform", intf, intf.qualifiedName+": "
			    		+ListenerDef.name+".property cannot be null or empty")
		    	}
	  		}
		   	buf.toString
	  	} else {
	  		"null"
	  	}
   }

  /** Adds the Type field */
  private def void addTypeField(TypeDeclaration intf,
  	MutableInterfaceDeclaration meta, BeanInfo beanInfo, String allProps) {
    val pkg = beanInfo.pkgName
    val simpleName = beanInfo.simpleName
    if (meta.findDeclaredField(metaTypeFieldName(simpleName)) === null) {
      val parents = new StringBuilder
      for (p : beanInfo.parents) {
      	val parent = beanInfoToTypeCode(p, pkg)
      	if (parent === null) {
            val msg = p.qualifiedName+" unknown; not adding as parent of "
              +beanInfo.qualifiedName
            val pTD = findTypeGlobally(p.qualifiedName)
            if ((pTD !== null) && isMarker(pTD)) {
              warn(BeanProcessor, "transform", intf, msg)
            } else {
              error(BeanProcessor, "transform", intf, msg)
            }
      	} else if (p.isBean) {
          parents.append(parent)
          parents.append(', ')
      	}
      }
      if (parents.length > 0) {
        parents.length = parents.length - 2
      }
      val beanType = newTypeReference(beanInfo.qualifiedName)
      val props = if (allProps.empty) "" else ", "+allProps
      val kind = if (beanInfo.isBean) Kind.name+".Trait" else Kind.name+".Data"
      meta.addField(metaTypeFieldName(simpleName)) [
        visibility = Visibility.PUBLIC
        final = true
        static = true
        type = newTypeReference(Type, beanType)
        // STEP 16.1
        val validators = findPropertyValidators(intf, beanInfo)
        val listeners = findPropertyListeners(intf, beanInfo)
        if (beanInfo.isInstance) {
	        initializer = [
	          '''BUILDER.newType(«simpleName».class, new «providerName(pkg, simpleName)»(), «kind»,
	          «validators», «listeners»,
	          new Type[] {«parents»}«props»)'''
	        ]
        } else {
	        initializer = [
	          '''BUILDER.newType(«simpleName».class, null, «kind»,
	          «validators», «listeners»,
	          new Type[] {«parents»}«props»)'''
	        ]
        }
        docComment = "Type field for "+beanInfo.qualifiedName
      ]
      warn(BeanProcessor, "transform", intf, "Adding "+cameCaseToSnakeCase(simpleName)+" to "+meta.qualifiedName)
    }
  }

  /** Returns the name of the field for the type in Meta */
  private def String metaTypeFieldName(String simpleName) {
    cameCaseToSnakeCase(simpleName)
  }

  /** Returns the name of the package field */
  private def String packageFieldName(String pkgName) {
    "PACKAGE"
  }

  /** Adds the package */
  private def void addPackageField(Map<String,Object> processingContext,
    MutableInterfaceDeclaration meta, List<TypeDeclaration> allTypes,
    String pkgName) {
    val name = packageFieldName(pkgName)
    if (meta.findDeclaredField(name) === null) {
      val allTypesStr = new StringBuilder
      for (t : allTypes) {
      	if (accept(processingContext, t)) {
          if (allTypesStr.length > 0) {
            allTypesStr.append(", ")
          }
          allTypesStr.append(cameCaseToSnakeCase(t.simpleName))
        }
      }
      meta.addField(name) [
        visibility = Visibility.PUBLIC
        final = true
        static = true
        type = newTypeReference(TypePackage)
        initializer = [
          '''BUILDER.newTypePackage(«allTypesStr»)'''
        ]
        docComment = "Package field for the current package"
      ]
      warn(BeanProcessor, "transform", meta, "Adding "+name+" to "+meta.qualifiedName)
    }
  }

  /** Creates the implementation class for a type */
  private def MutableClassDeclaration createImplementation(Map<String,Object> processingContext, MutableInterfaceDeclaration mtd) {
    val qualifiedName = mtd.qualifiedName
    val index = qualifiedName.lastIndexOf(DOT)
    val pkgName = qualifiedName.substring(0,index)
    val simpleName = qualifiedName.substring(index+1)
    val implName = implName(pkgName, simpleName)
    val beanInfo = beanInfo(processingContext, mtd)
    val impl = getClass(implName)
    warn(BeanProcessor, "transform", mtd, implName+" will be implemented")
    var first = beanInfo.parents.head()
    if ((first !== null) && (first.qualifiedName == BEAN_QUALIFIED_NAME)) {
		if (beanInfo.parents.length === 1) {
			first = null
		} else {
			first = beanInfo.parents.get(1)
		}
    }
    val entity = findTypeGlobally(Entity)
    if ((first !== null) && first.isBean) {
      val parentName = implName(first.pkgName, first.simpleName)
      impl.setExtendedClass(newTypeReference(parentName))
    } else if (entity.isAssignableFrom(mtd)) {
      impl.setExtendedClass(newTypeReference(_EntityImpl))
    } else {
      impl.setExtendedClass(newTypeReference(_BeanImpl))
    }
    impl.setImplementedInterfaces(newArrayList(newTypeReference(qualifiedName)))
    // STEP 27
    // Implementation class should have comments too.
    impl.setDocComment("Implementation class for "+qualifiedName)
    if (!beanInfo.isInstance) {
    	impl.setAbstract(true)
    }
    // STEP 25
    // Add _BeanImpl annotation to the implementation class.
    impl.addAnnotation(newAnnotationReference(BeanImplemented, [
    	set("implemented", newTypeReference(mtd))
	]))
    impl
  }

  /** The Impl extends either the impl of the first parent, or BaseImpl or EntityImpl appropriately */
  private def void addImplementationConstructors(Map<String,Object> processingContext,
  	BeanInfo beanInfo, MutableInterfaceDeclaration mtd, MutableClassDeclaration impl) {
	// STEP 20
    val qualifiedName = mtd.qualifiedName
    val index = qualifiedName.lastIndexOf(DOT)
    val pkgName = qualifiedName.substring(0,index)
    val simpleName = qualifiedName.substring(index+1)
	val typeTypeRef = newTypeReference(Type)
	if (impl.findDeclaredConstructor(typeTypeRef) === null) {
		// STEP 10
		val myInits = new ArrayList<String>()
		if (beanInfo.innerImpl != null) {
			myInits.addAll(beanInfo.innerImpl.hasInit)
		}
		val piBI = findParentBeanInfo(processingContext, impl)
		if ((piBI != null) && (piBI.innerImpl != null)) {
			myInits.removeAll(piBI.innerImpl.hasInit)
		}
		impl.addConstructor[
			addParameter("metaType", typeTypeRef)
			visibility = Visibility.PROTECTED
			body = [
				'''super(metaType);
«FOR init : myInits»
«init»._init_(this);
«ENDFOR»
				'''
			]
			docComment = "Creates a new "+qualifiedName+" taking it's metaType as parameter"
		]
	}
	if ((impl.findDeclaredConstructor() === null) && beanInfo.isInstance) {
		val bodyText = '''this(«pkgName».Meta.«metaTypeFieldName(simpleName)»);'''
		impl.addConstructor[
			visibility = Visibility.PUBLIC
			body = [
				bodyText
			]
			docComment = "Creates a new "+qualifiedName+" with it's default metaType"
		]
	}
  }

  /** Generates the field for the given property */
  private def void generatePropertyField(Map<String, Object> processingContext,
    MutableInterfaceDeclaration intf, MutableClassDeclaration impl,
    BeanInfo beanInfo, PropertyInfo propInfo) {
	val isVirtual = propInfo.virtualProp
    if (!isVirtual && impl.findDeclaredField(propInfo.name) === null) {
      val propInfoType = if (propInfo.isMap) {
  	  	val start = propInfo.type.indexOf('<')
  	  	MapBeanImpl.name+propInfo.type.substring(start)
  	  } else if (propInfo.colType === null)
      	propInfo.type
  	  else {
  	  	// The field must be CollectionBeanImpl, it looks like it can be List OR Set
  	  	val start = propInfo.type.indexOf('<')
  	  	CollectionBeanImpl.name+propInfo.type.substring(start)
  	  }
      val doc = propInfo.comment
      impl.addField(propInfo.name) [
        visibility = Visibility.PRIVATE
        final = false
        static = false
        type = newTypeReferenceWithGenerics(propInfoType)
        // STEP 31
        // Comments on properties must be transfered to generated code
        if (doc.empty) {
          docComment = propInfo.name+" Field"
        } else {
          docComment = doc+" Field"
        }
      ]
      warn(BeanProcessor, "transform", intf, propInfo.name+" added to "+impl.qualifiedName)
    }
  }

    private def castForColProp(PropertyInfo propInfo) {
  	  	val start = propInfo.type.indexOf('<')
  	  	if (start < 0)
  	  		""
  		else if (propInfo.isMap)
	  		"("+MapBeanImpl.name+propInfo.type.substring(start)+") "
  		else if (propInfo.isCol)
	  		"("+CollectionBeanImpl.name+propInfo.type.substring(start)+") "
    }

	private def checkComponentType(MutableClassDeclaration impl, BeanInfo beanInfo,
			PropertyInfo propInfo, String componentType, String alternativeName,
			BeanInfo componentTypeBeanInfo) {
		if (componentType === null) {
			error(BeanProcessor, "transform", impl, "Could not find Type for "+alternativeName
				+" in "+beanInfo.qualifiedName+"."+propInfo.name)
			"?"
		} else {
			val index = alternativeName.indexOf('<')
			if (index < 0)
				componentType
			else {
				// The "Type constant", as defined in some Meta, never has specified generic parameters.
				// But the collection/map expects them, so we need that ugly cast.
				"(com.blockwithme.meta.Type<"+alternativeName+">) (com.blockwithme.meta.Type) "+componentType
			}
		}
	}

	/** Generates the getter, setter for the given property */
	private def void generatePropertyMethods(Map<String, Object> processingContext,
		MutableInterfaceDeclaration intf, MutableClassDeclaration impl, BeanInfo beanInfo, PropertyInfo propInfo) {
		val propertyMethodName = propertyMethodName(propInfo);
		val propertyFieldName = beanInfo.pkgName+".Meta."+getPropertyFieldNameInMeta(beanInfo.simpleName, propInfo)
		val isVirtual = propInfo.virtualProp
		val doc = propInfo.comment
		val propTypeRef = newTypeReferenceWithGenerics(propInfo.type)
		val colType = propInfo.colType
		val colOrMap = ((colType !== null) || propInfo.isMap)
		val tfu = propertyToXetterSuffix(propInfo.name)
		val getter = if (colOrMap) "getRaw"+tfu else "get"+tfu
		if (!isVirtual && (impl.findDeclaredMethod(getter) === null)) {
			val bodyText = '''return interceptor.get«propertyMethodName»(this, «propertyFieldName», «propInfo.name»);'''
			onMethodAdded(impl.addMethod(getter) [
				visibility = Visibility.PUBLIC
				final = true
				static = false
				returnType = propTypeRef
				body = [
					bodyText
				]
				// STEP 31
				// Comments on properties must be transfered to generated code
				if (doc.empty) {
					docComment = "Getter for "+propInfo.name
				} else {
					docComment = "Getter for "+doc
				}
			])
			warn(BeanProcessor, "transform", intf, getter+" added to "+impl.qualifiedName)
		}
		val setter = "set"+tfu
		val valueType = propTypeRef
		if (impl.findDeclaredMethod(setter, valueType) === null) {
			var genSetter = if (!isVirtual) true else {
				(impl.findMethod(setter, valueType) == null)
			}
			if (genSetter) {
				val bodyText0 = '''«propInfo.name» = «castForColProp(propInfo)»interceptor.set«propertyMethodName»(this, «propertyFieldName», «propInfo.name», newValue);
return this;'''
				val bodyText = if (isVirtual) "throw new UnsupportedOperationException();" else if (!colOrMap) bodyText0 else
			'''checkNullOrImmutable(newValue);
'''+bodyText0
				onMethodAdded(impl.addMethod(setter) [
					visibility = Visibility.PUBLIC
					static = false
					returnType = newTypeReference(impl.qualifiedName)
					addParameter("newValue", valueType)
					body = [
						bodyText
					]
					// STEP 31
					// Comments on properties must be transfered to generated code
			        if (colOrMap) {
				        if (doc.empty) {
				          docComment = "Setter (accepts only null!) for "+propInfo.name
				        } else {
				          docComment = "Setter (accepts only null!) for "+doc
				        }
			        } else {
				        if (doc.empty) {
				          docComment = "Setter for "+propInfo.name
				        } else {
				          docComment = "Setter for "+doc
				        }
			        }
				])
				warn(BeanProcessor, "transform", intf, setter+" added to "+impl.qualifiedName)
			}
		}
		if (!isVirtual && (colType !== null)) {
			val creator = "get"+tfu
			if (impl.findDeclaredMethod(creator) === null) {
				// TODO Verify if we should match "exact type" for the values, and specify
				// it in the call to newFixedSizeList() and possibly use different config constants
				val propType = propInfo.type
				val index = propType.indexOf("<")
				val componentType = propType.substring(index+1, propType.length-1)
				val config = if (propInfo.fixedSize > 0) {
					CollectionBeanConfig.name+".newFixedSizeList("+propInfo.fixedSize+", false)"
				} else {
					// Generated code does not compile *in Maven* if I use a switch!
					if (CollectionPropertyType.unorderedSet == colType) {
						CollectionBeanConfig.name+".UNORDERED_SET"
					} else if (CollectionPropertyType.orderedSet == colType) {
						CollectionBeanConfig.name+".ORDERED_SET"
					} else if (CollectionPropertyType.sortedSet == colType) {
						CollectionBeanConfig.name+".SORTED_SET"
					} else if (CollectionPropertyType.hashSet == colType) {
						CollectionBeanConfig.name+".HASH_SET"
					} else if (CollectionPropertyType.list == colType) {
						if (propInfo.nullAllowed)
							CollectionBeanConfig.name+".NULL_LIST"
						else
							CollectionBeanConfig.name+".LIST"
					} else {
						throw new IllegalStateException(""+colType)
					}
				}
				val componentTypeBeanInfo = beanInfo(processingContext, componentType)
      			val componentTypeType = beanInfoToTypeCode(componentTypeBeanInfo, beanInfo.pkgName)
      			val componentTypeType2 = checkComponentType(impl, beanInfo, propInfo,
      				componentTypeType, componentType, componentTypeBeanInfo)
      			val bodyText = '''«propTypeRef» result = «getter»();
if (result == null) {
	«propInfo.name» = «castForColProp(propInfo)»interceptor.set«propertyMethodName»(this, «propertyFieldName», «propInfo.name», new «CollectionBeanImpl.name»<«componentType»>(«Meta.name».COLLECTION_BEAN, «componentTypeType2»,«config»));
	result = «getter»();
}
return result;'''
				onMethodAdded(impl.addMethod(creator) [
					visibility = Visibility.PUBLIC
					final = true
					static = false
					returnType = propTypeRef
					body = [
						bodyText
					]
					// STEP 31
					// Comments on properties must be transfered to generated code
					if (doc.empty) {
						docComment = "Creator for "+propInfo.name
					} else {
						docComment = "Creator for "+doc
					}
				])
				warn(BeanProcessor, "transform", intf, creator+" added to "+impl.qualifiedName)
			}
		} else if (!isVirtual && propInfo.isMap) {
			val creator = "get"+tfu
			if (impl.findDeclaredMethod(creator) === null) {
				val propType = propInfo.type
				val start = propType.indexOf("<")
	          	val componentTypeNames = propType.substring(start+1, propType.length - 1)
	          	val coma = componentTypeNames.indexOf(',')
	          	if (coma < 0) {
	          		throw new IllegalStateException("Bad Map Type: "+propType)
	          	}
	          	val coma2 = componentTypeNames.lastIndexOf(',')
	          	if (coma !== coma2) {
	          		throw new UnsupportedOperationException(
	          			"Map Property parameters cannot contain ',': "+propInfo.name+" "+propType)
	          	}
	          	val keyTypeName = componentTypeNames.substring(0, coma).trim
	          	val valueTypeName = componentTypeNames.substring(coma+1).trim
	          	val keyTypeBeanInfo = beanInfo(processingContext, keyTypeName)
      			val keyTypeType = beanInfoToTypeCode(keyTypeBeanInfo, beanInfo.pkgName)
      			val keyTypeType2 = checkComponentType(impl, beanInfo, propInfo, keyTypeType, keyTypeName, keyTypeBeanInfo)
      			val valueTypeBeanInfo = beanInfo(processingContext, valueTypeName)
      			val valueTypeType = beanInfoToTypeCode(valueTypeBeanInfo, beanInfo.pkgName)
      			val valueTypeType2 = checkComponentType(impl, beanInfo, propInfo, valueTypeType, valueTypeName, valueTypeBeanInfo)
      			val bodyText = '''«propTypeRef» result = «getter»();
if (result == null) {
	«propInfo.name» = «castForColProp(propInfo)»interceptor.set«propertyMethodName»(this, «propertyFieldName», «propInfo.name», new «MapBeanImpl.name»<«keyTypeName»,«valueTypeName»>(«Meta.name».MAP_BEAN, «keyTypeType2»,«valueTypeType2»));
	result = «getter»();
}
return result;'''
				onMethodAdded(impl.addMethod(creator) [
					visibility = Visibility.PUBLIC
					final = true
					static = false
					returnType = propTypeRef
					body = [
						bodyText
					]
					// STEP 31
					// Comments on properties must be transfered to generated code
					if (doc.empty) {
						docComment = "Creator for "+propInfo.name
					} else {
						docComment = "Creator for "+doc
					}
				])
				warn(BeanProcessor, "transform", intf, creator+" added to "+impl.qualifiedName)
			}
		}

		if (isVirtual && (intf.findDeclaredMethod(setter, valueType) == null)) {
			onMethodAdded(intf.addMethod(setter) [
				visibility = Visibility.PUBLIC
				static = false
				returnType = newTypeReference(intf.qualifiedName)
				addParameter("newValue", valueType)
				// STEP 31
				// Comments on properties must be transfered to generated code
		        if (colOrMap) {
			        if (doc.empty) {
			          docComment = "Setter (accepts only null!) for "+propInfo.name
			        } else {
			          docComment = "Setter (accepts only null!) for "+doc
			        }
		        } else {
			        if (doc.empty) {
			          docComment = "Setter for "+propInfo.name
			        } else {
			          docComment = "Setter for "+doc
			        }
		        }
			])
			warn(BeanProcessor, "transform", intf, setter+"(virtual) added to "+intf.qualifiedName)
			if (intf.findDeclaredMethod(setter, valueType) == null) {
				error(BeanProcessor, "transform", intf, setter+" STILL NOT VISIBLE even after adding it to "+intf.qualifiedName)
			}
		}
	}

	/** Record the BeanInfo in form of an annotation */
	private def void recordBeanInfo(MutableInterfaceDeclaration target, BeanInfo beanInfo) {
		val _biTD = findTypeGlobally(_BeanInfo)
		if (target.findAnnotation(_biTD) === null) {
			target.addAnnotation(newAnnotationReference(_biTD, [
				var i = 0
				if (!beanInfo.parents.empty) {
					val parents = <TypeReference>newArrayOfSize(beanInfo.parents.size)
					for (p : beanInfo.parents) {
						parents.set(i, newTypeReference(p.qualifiedName))
						i = i + 1
					}
					set("parents", parents)
				}

				if (!beanInfo.properties.empty) {
					val props = <String>newArrayOfSize(beanInfo.properties.size*PROP_INFO_FIELDS)
					i = 0
					for (p : beanInfo.properties) {
						props.set(i, requireNonNull(p.name, p+": name"))
						i = i + 1
						props.set(i, requireNonNull(p.type, p+": type"))
						i = i + 1
						props.set(i, requireNonNull(p.comment, p+": comment"))
						i = i + 1
						props.set(i, if (p.colType === null) "" else p.colType)
						i = i + 1
						props.set(i, String.valueOf(p.fixedSize))
						i = i + 1
						props.set(i, String.valueOf(p.nullAllowed))
						i = i + 1
						props.set(i, String.valueOf(p.virtualProp))
						i = i + 1
						props.set(i, p.min)
						i = i + 1
						props.set(i, p.max)
						i = i + 1
						props.set(i, p.softMin)
						i = i + 1
						props.set(i, p.softMax)
						i = i + 1
					}
					set("properties", props)
				}

				if (!beanInfo.validity.empty) {
					val String[] validity = <String>newArrayOfSize(beanInfo.validity.size)
					set("validity", beanInfo.validity.toArray(validity))
				}

				setBooleanValue("isBean", beanInfo.isBean)
				setBooleanValue("isInstance", beanInfo.isInstance)

				if (beanInfo.innerImpl != null) {
					val declarationToClass = beanInfo.innerImpl.declarationToClass
					val String[] innerImpl = <String>newArrayOfSize(
						2 + declarationToClass.size*2 + beanInfo.innerImpl.hasInit.size)
					var j = 0
					innerImpl.set(j++, beanInfo.innerImpl.qualifiedName)
					innerImpl.set(j++, String.valueOf(declarationToClass.size))
					for(e : declarationToClass.entrySet) {
						innerImpl.set(j++, e.key)
						innerImpl.set(j++, e.value)
					}
					for (hi : beanInfo.innerImpl.hasInit) {
						innerImpl.set(j++, hi)
					}
					set("innerImpl", innerImpl)
				}
			]))
		}
	}

	/** Extract recorded BeanInfo data */
	private def BeanInfo extractBeanInfo(Map<String,Object> processingContext, String qualifiedName, AnnotationReference annotRef) {
		val _parents = annotRef.getClassArrayValue("parents")
		val _props = annotRef.getStringArrayValue("properties")
		val _validity = annotRef.getStringArrayValue("validity")
		val isBean = annotRef.getBooleanValue("isBean")
		val isInstance = annotRef.getBooleanValue("isInstance")
		val sortKeyes = annotRef.getStringArrayValue("sortKeyes")
		val innerImpl = annotRef.getStringArrayValue("innerImpl")

		val parentList = <BeanInfo>newArrayList()
		for (p : _parents) {
			val qname = p.name
			if (!qname.contains('.')) {
				throw new IllegalStateException("Got a non-absolute type name: "+qname)
			}
			parentList.add(beanInfo(processingContext, qname))
		}

		val properties = <PropertyInfo>newArrayOfSize(_props.size/PROP_INFO_FIELDS)
		var i = 0
		while (i < _props.size) {
			val name = _props.get(i)
			val type = _props.get(i+1)
			val comment = _props.get(i+2)
			val colTypeName = _props.get(i+3)
			val colType = if (colTypeName.empty) null else colTypeName
			val fixedSize = Integer.parseInt(_props.get(i+4))
			val nullAllowed = Boolean.parseBoolean(_props.get(i+5))
			val virtualProp = Boolean.parseBoolean(_props.get(i+6))
		  	val min = _props.get(i+7)
		  	val max = _props.get(i+8)
		  	val softMin = _props.get(i+9)
		  	val softMax = _props.get(i+10)
			properties.set(i/PROP_INFO_FIELDS, new PropertyInfo(name, type, comment, colType,
				fixedSize, nullAllowed, virtualProp, min, max, softMin, softMax))
			i = i + PROP_INFO_FIELDS
		}
		val innerImplObj = new InnerImpl(innerImpl.get(0))
		val len = Integer.parseInt(innerImpl.get(1))
		for (i = 2; i < 2+len*2; i+=2) {
			val key = innerImpl.get(i)
			val value = innerImpl.get(i+1)
			innerImplObj.declarationToClass.put(key,value)
		}
		for (i = 2+len*2; i < innerImpl.length; i++) {
			val hi = innerImpl.get(i)
			innerImplObj.hasInit.add(hi)
		}
		new BeanInfo(qualifiedName,
			parentList.toArray(newArrayOfSize(parentList.size)),
			properties,
			newArrayList(_validity),
			isBean, isInstance, sortKeyes, innerImplObj)
	}

	/** Generates the "copy methods" */
	private def genCopyMethods(MutableInterfaceDeclaration mtd, MutableClassDeclaration impl) {
	    // STEP 37
	    // Generate the "copy methods" in the Type
		if (mtd.findDeclaredMethod("copy") === null) {
			onMethodAdded(mtd.addMethod("copy") [
				visibility = Visibility.PUBLIC
				final = false
				static = false
				returnType = newTypeReference(mtd)
				docComment = "Returns a full mutable copy"
			])
			warn(BeanProcessor, "transform", mtd, "copy() added to "+mtd.qualifiedName)
		}

		if (mtd.findDeclaredMethod("snapshot") === null) {
			onMethodAdded(mtd.addMethod("snapshot") [
				visibility = Visibility.PUBLIC
				final = false
				static = false
				returnType = newTypeReference(mtd)
				docComment = "Returns an immutable copy"
			])
			warn(BeanProcessor, "transform", mtd, "snapshot() added to "+mtd.qualifiedName)
		}

		if (mtd.findDeclaredMethod("wrapper") === null) {
			onMethodAdded(mtd.addMethod("wrapper") [
				visibility = Visibility.PUBLIC
				final = false
				static = false
				returnType = newTypeReference(mtd)
				docComment = "Returns a lightweight mutable copy"
			])
			warn(BeanProcessor, "transform", mtd, "wrapper() added to "+mtd.qualifiedName)
		}

		// STEP 38
		// Generate the "copy methods" in the implementation
		if (impl.findDeclaredMethod("copy") === null) {
			val bodyText = '''return («mtd.qualifiedName») doCopy();'''
			onMethodAdded(impl.addMethod("copy") [
				visibility = Visibility.PUBLIC
				final = false
				static = false
				returnType = newTypeReference(mtd)
				body = [
					bodyText
				]
				docComment = "Returns a full mutable copy"
			])
			warn(BeanProcessor, "transform", mtd, "copy() added to "+impl.qualifiedName)
		}

		if (impl.findDeclaredMethod("snapshot") === null) {
			val bodyText = '''return («mtd.qualifiedName») doSnapshot();'''
			onMethodAdded(impl.addMethod("snapshot") [
				visibility = Visibility.PUBLIC
				final = false
				static = false
				returnType = newTypeReference(mtd)
				body = [
					bodyText
				]
				docComment = "Returns an immutable copy"
			])
			warn(BeanProcessor, "transform", mtd, "snapshot() added to "+impl.qualifiedName)
		}

		if (impl.findDeclaredMethod("wrapper") === null) {
			val bodyText = '''return («mtd.qualifiedName») doWrapper();'''
			onMethodAdded(impl.addMethod("wrapper") [
				visibility = Visibility.PUBLIC
				final = false
				static = false
				returnType = newTypeReference(mtd)
				body = [
					bodyText
				]
				docComment = "Returns a lightweight mutable copy"
			])
			warn(BeanProcessor, "transform", mtd, "wrapper() added to "+impl.qualifiedName)
		}
	}

	/** Comparable type name */
	static val COMPARABLE = Comparable.name

	/** Generates the "compareTo() methods" */
	private def genCompareToMethods(MutableInterfaceDeclaration mtd, MutableClassDeclaration impl,
		String[] sortKeyes) {
		if (sortKeyes.length > 0) {
			val primitiveInt = processorUtil.primitiveInt
			val param = mtd.newTypeReference()
			val paramList = #[param]
			// STEP 39
			// Optionally extend Comparable in Type
			if (!mtd.extendedInterfaces.exists[name == COMPARABLE]) {
				val newIntfs = <TypeReference>newArrayList()
				newIntfs.addAll(mtd.extendedInterfaces)
				newIntfs.add(newTypeReference(COMPARABLE, param))
				mtd.extendedInterfaces = newIntfs
				warn(BeanProcessor, "genCompareToMethods", mtd, COMPARABLE+" extended in "+mtd.qualifiedName)
			}

			// STEP 40
			// Generate optional compareTo() method in implementation
			if (impl.findDeclaredMethod("compareTo", paramList) === null) {
				val bodyText = '''
						if (other == null) {
							return 1;
						}
						int result = 0;
						«FOR sortKey : sortKeyes»
						if (result == 0) {
							result = compare(get«propertyToXetterSuffix(sortKey)»(), other.get«propertyToXetterSuffix(sortKey)»());
						}
						«ENDFOR»
						return result;'''
				onMethodAdded(impl.addMethod("compareTo") [
					visibility = Visibility.PUBLIC
					final = false
					static = false
					addParameter("other", param)
					returnType = primitiveInt
					body = [
						bodyText
					]
					docComment = "Compares to other"
				])
				warn(BeanProcessor, "genCompareToMethods", mtd, "compareTo(?) added to "+impl.qualifiedName)
			}
		}
	}


	/** Make sure "instance" Beans have all their abstract methods implemented. */
	def private void checkAbstractOrImplemented(BeanInfo beanInfo, MutableInterfaceDeclaration mtd,
		MutableClassDeclaration impl) {
		if (beanInfo.isInstance && beanInfo.isBean) {
			val allImplMethods = impl.findAllMethods().filter[!(static || native || visibility == Visibility.PRIVATE)]
			val unimplemented = new ArrayList<MethodDeclaration>
			for (m : allImplMethods) {
				if (m.abstract) {
					unimplemented.add(m)
				}
			}
			if (!unimplemented.empty) {
				// TODO Change to error, once findAllMethods() works correctly
				warn(BeanProcessor, "checkAbstractOrImplemented", mtd, "Not implemented(?): "
					+unimplemented.map[signatureWithoutGenerics])
			}
		}
	}

  /** Allows another Processor to add the Type field to Meta */
  private def void addTypeField(Map<String,Object> processingContext, TypeDeclaration type) {
	// STEP 30
    // Non-Beans types, which should have been registered in Meta, but could not.
  	val beanInfo = beanInfo(processingContext, type.qualifiedName)
	val meta = getInterface(metaName(beanInfo.pkgName))
  	if (meta.findDeclaredField("BUILDER") === null) {
 		if (type instanceof MutableEnumerationTypeDeclaration) {
			// Try to add enum mdt to Meta
			warn(BeanProcessor, "BeanProcessor.transform", type, "Found enum Type(delayed): "+type.qualifiedName)
		} else if (type instanceof MutableClassDeclaration) {
			// Try to add @Data mdt to Meta
			warn(BeanProcessor, "BeanProcessor.transform", type, "Found @Data Type(delayed): "+type.qualifiedName)
		}
		var delayedNonBeans = processingContext.get(BP_NON_BEAN_TODO) as ArrayList<TypeDeclaration>
		if (delayedNonBeans === null) {
			delayedNonBeans = new ArrayList<TypeDeclaration>
			processingContext.put(BP_NON_BEAN_TODO, delayedNonBeans)
		}
  		delayedNonBeans.add(type)
  	} else {
 		if (type instanceof MutableEnumerationTypeDeclaration) {
			// Try to add enum mdt to Meta
			warn(BeanProcessor, "BeanProcessor.transform", type, "Found enum Type: "+type.qualifiedName)
		} else if (type instanceof MutableClassDeclaration) {
			// Try to add @Data mdt to Meta
			warn(BeanProcessor, "BeanProcessor.transform", type, "Found @Data Type: "+type.qualifiedName)
		}
		addTypeField(type, meta, beanInfo, "")
	}
  }

	/** Register new types, to be generated later. */
	override void register(Map<String,Object> processingContext, TypeDeclaration td,
		RegisterGlobalsContext context) {
		if (td instanceof InterfaceDeclaration) {
			val qualifiedName = td.qualifiedName
			// STEP 1-4
			val beanInfo = beanInfo(processingContext, td)

			if (beanInfo.validity.empty) {
				val index = qualifiedName.lastIndexOf(DOT)
				val pkgName = qualifiedName.substring(0,index)
				val simpleName = qualifiedName.substring(index+1)

				// STEP 5
				// Registering the implementation, if needed
				registerClass(td, context, implName(pkgName, simpleName))

				// STEP 6
				// Registering the Provider, if needed
				if (beanInfo.isInstance) {
					registerClass(td, context, providerName(pkgName, simpleName))
				}

				// STEP 7
				// Registering the Meta, if needed
				registerInterface(td, context, metaName(pkgName))

				// STEP 8
				// Registering all Property Accessors, if needed
				for (p : beanInfo.properties) {
					registerClass(td, context, propertyAccessorName(pkgName, simpleName, p.name))
				}
			} else {
				error(BeanProcessor, "register", td, qualifiedName
					+" cannot be processed because: "+beanInfo.validity)
				for (p : beanInfo.parents) {
					if (!p.validity.empty) {
						error(BeanProcessor, "register", td, "... "+p.qualifiedName
							+" cannot be processed because: "+p.validity)
					}
				}
			}
		}
	}

	/** Transform types, new or old. */
	override void transform(Map<String,Object> processingContext, MutableTypeDeclaration mtd,
		TransformationContext context) {
		if (mtd instanceof MutableInterfaceDeclaration) {
			val beanInfo = beanInfo(processingContext, mtd)
			val qualifiedName = beanInfo.qualifiedName
			if (beanInfo.validity.empty) {
				warn(BeanProcessor, "transform", mtd, qualifiedName+" will be transformed")
				val pkgName = beanInfo.pkgName

				// STEP 9
				// The fields are replaced with getters and setters
				for (f : mtd.declaredFields.toList) {
					processField(f, mtd)
				}

				// STEP 11
				importInnerImplIntoInterface(mtd, beanInfo)

				// STEP 13
				// A builder is created in Meta for that package
				val meta = getInterface(metaName(pkgName))
				addBuilderField(meta, mtd, processingContext)

				// STEP 14
				// For each type property, a property accessor class is generated
				var allProps = ""
				for (propInfo : beanInfo.properties) {
					val accessorName = implementPropertyAccessor(beanInfo, propInfo)
					// STEP 15
					// For each type property, a property object in the "Meta" interface is generated.
					val name = createPropertyConstant(mtd, meta, beanInfo, accessorName, propInfo)
					allProps = if (allProps.empty) name else allProps+", "+name
				}

				// STEP 16
				// For each type, a type Provider under impl package is created.
				if (beanInfo.isInstance) {
					createProvider(mtd, beanInfo)
				}

				// STEP 17
				// For each type, following the properties, a type instance is created.
				addTypeField(mtd, meta, beanInfo, allProps)

				// STEP 20
				// The Impl extends either the impl of the first parent, or BaseImpl or EntityImpl appropriately
				val impl = createImplementation(processingContext, mtd)

				// STEP 21
				// For all getters and setters in type, implementations are generated in Impl
				for (propInfo : beanInfo.properties) {
					generatePropertyField(processingContext, mtd, impl, beanInfo, propInfo)
				}

				// STEP 24
				// Add impl to all missing properties in Impl
				var firstParent = beanInfo.parents.head()
				if ((firstParent !== null) && !firstParent.isBean) {
					firstParent = null
				}
				val map = new HashMap<BeanInfo,PropertyInfo[]>
				for (e : beanInfo.allProperties.entrySet) {
					val key = e.key
					if ((key != qualifiedName) && ((firstParent === null) || !firstParent.allProperties.containsKey(key))) {
						// Missing properties!
						val bi = processingContext.get(cacheKey(key)) as BeanInfo
						for (p : e.value) {
							map.put(bi, e.value)
							generatePropertyField(processingContext, mtd, impl, bi, p)
						}
					}
				}

				// STEP 20
				// The Impl extends either the impl of the first parent, or BaseImpl or EntityImpl appropriately
				addImplementationConstructors(processingContext, beanInfo, mtd, impl)

				// STEP 21
				// For all getters and setters in type, implementations are generated in Impl
				for (propInfo : beanInfo.properties) {
					generatePropertyMethods(processingContext, mtd, impl, beanInfo, propInfo)
				}

				// STEP 23
				// For all imported methods from the Type.Impl, delegators are generated in Impl
				importInnerImplIntoImpl(processingContext, mtd, impl, beanInfo)

				// STEP 24
				// Add impl to all missing properties in Impl
				for (e : map.entrySet) {
					for (p : e.value) {
						generatePropertyMethods(processingContext, mtd, impl, e.key, p)
					}
				}

				// STEP 34
				// @_BeanInfo must be generated on the type
				recordBeanInfo(mtd, beanInfo)

				// STEP 36
				// Type should extend Bean
				val bean = findTypeGlobally(com.blockwithme.meta.beans.Bean)
				if (!bean.isAssignableFrom(mtd)) {
					val parents = <TypeReference>newArrayList()
					parents.addAll(mtd.extendedInterfaces)
					parents.add(newTypeReference(com.blockwithme.meta.beans.Bean))
					mtd.extendedInterfaces = parents
				}

				genCopyMethods(mtd, impl)

				genCompareToMethods(mtd, impl, beanInfo.sortKeyes)

			    // STEP 26
			    // Make sure "instance" Beans have all their abstract methods implemented.
			    checkAbstractOrImplemented(beanInfo, mtd, impl)
			} else {
				warn(BeanProcessor, "transform", mtd, qualifiedName
					+" will NOT be transformed, because: "+beanInfo.validity)
			}
			// else we already told the user mtd is bugged
		} else {
			addTypeField(processingContext, mtd)
		}
	}

	/** Called when the transform phase for the current file is done. */
	override void afterTransform(Map<String,Object> processingContext, String pkgName, TransformationContext context) {
		// Post-type-processing phases
		warn(BeanProcessor, "transform", null, "afterTransform("+pkgName+")")

		val meta = getInterface(metaName(pkgName))

		// STEP 18
		// After all types, a package meta-object is created.
		val allTypes = processingContext.get(PC_ALL_FILE_TYPES) as List<TypeDeclaration>
		addPackageField(processingContext, meta, allTypes, pkgName)
  }
}
