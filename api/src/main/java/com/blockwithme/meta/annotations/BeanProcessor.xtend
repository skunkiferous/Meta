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
import com.blockwithme.meta.Hierarchy
import com.blockwithme.meta.HierarchyBuilder
import com.blockwithme.meta.JavaMeta
import com.blockwithme.meta.Kind
import com.blockwithme.meta.Type
import com.blockwithme.meta.TypePackage
import com.blockwithme.meta.beans.Entity
import com.blockwithme.meta.beans.impl._BeanImpl
import com.blockwithme.meta.beans.impl._EntityImpl
import java.lang.annotation.ElementType
import java.lang.annotation.Inherited
import java.lang.annotation.Retention
import java.lang.annotation.RetentionPolicy
import java.lang.annotation.Target
import java.util.HashMap
import java.util.HashSet
import java.util.List
import java.util.Map
import java.util.Set
import javax.inject.Provider
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.RegisterGlobalsContext
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.AnnotationReference
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableFieldDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableInterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import org.eclipse.xtend.lib.macro.declaration.Visibility

import static java.util.Objects.*
import com.blockwithme.meta.HierarchyBuilderFactory
import com.blockwithme.meta.beans.CollectionBean
import com.blockwithme.meta.beans.impl.CollectionBeanImpl
import com.blockwithme.meta.beans.CollectionBeanConfig

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
@Active(MagicAnnotationProcessor)
annotation Bean {
	boolean instance = false
	String[] sortKeyes = #[]
}

/**
 * The possible types of collection properties.
 * This type *should be an enum*, but some bug in Xtend prevent me from using an enum.
 * Since I cannot create a *simple* test-case that shows the bug, they just won't fix it.
 */
interface CollectionPropertyType {
	/** Are we an unordered set? */
	val unorderedSet = "unorderedSet"
	/** Are we an ordered set? */
	val orderedSet = "orderedSet"
	/** Are we a sorted set? */
	val sortedSet = "sortedSet"
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
 * @author monster
 */
@Target(ElementType.FIELD)
@Retention(RetentionPolicy.CLASS)
annotation SortedSetProperty {
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
}

/**
 * Annotates a property field as a "virtual" property.
 * Virtual properties are mostly used in manually created base-class,
 * and in third-party classes. Here, this causes a "getter" to be defined,
 * that contains the code specified in the getterJavaCode parameter
 * (";" is added automatically), but no field is generated. If setterJavaCode
 * is not empty, a setter is generated too (parameter is always called "newValue").
 *
 * @author monster
 */
@Target(ElementType.FIELD)
@Retention(RetentionPolicy.CLASS)
annotation VirtualProperty {
	String getterJavaCode
	String setterJavaCode = ""
}

@Data
package class PropertyInfo {
  String name
  String type
  String comment
  /*CollectionPropertyType*/String colType
  int fixedSize
  /** Virtual Property getter implementation */
  String getterJavaCode
  /** Optional Virtual Property setter implementation */
  String setterJavaCode
}

@Data
package class BeanInfo {
  String qualifiedName
  BeanInfo[] parents
  PropertyInfo[] properties
  List<String> validity
  boolean isBean
  boolean isInstance
  String[] sortKeyes
  def pkgName() {
    qualifiedName.substring(0,qualifiedName.lastIndexOf('.'))
  }
  def simpleName() {
    qualifiedName.substring(qualifiedName.lastIndexOf('.')+1)
  }
  // STEP 23
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
    String[] properties = #[] //name0,type0,comment0,colType0,fixedSize0,getterJavaCode0,setterJavaCode0...
    String[] validity = #[]
	String[] sortKeyes = #[]
    boolean isBean
    boolean isInstance
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
 * (REMOVED) 8) For each type, the internal API interface (_X) is registered, if not defined yet
 * 9) For each type property, an Accessor type under impl package is declared, if not defined yet
 * GENERATE:
 * 10) For each type, the fields are replaced with getters and setters
 * (REMOVED) 11) If the property starts with _, the getter and setter goes in _Type
 * (REMOVED) 12) _Type must extend Type
 * 13) A builder is created in Meta for that package
 * 14) For each type property, a property accessor class is generated
 * 15) For each type property, a property object in the "Meta" interface is generated.
 * 16) For each type, a type Provider under impl package is created.
 * 17) For each type, following the properties, a type instance is created.
 * 18) After all types, a package meta-object is created.
 * 19) The list of dependencies for the Hierarchy is computed.
 * (REMOVED) 20) After the package, the hierarchy is created.
 * 21) The Impl extends either the impl of the first parent, or BaseImpl or EntityImpl appropriately
 * 22) For all getters and setters in type, implementations are generated in Impl
 * 23) If we have more then one parent, find out all missing properties
 * 24) Add impl to all missing properties in Impl
 * (REMOVED) 25) If a TypeExt class exists in the same file, add it's static methods as instance methods in Type
 * (REMOVED) 26) If a TypeExt class exists in the same file, add it's static methods as instance methods in TypeImpl
 * 27) Implementation class should have comments too.
 * 28) Comments should be generated for Meta too
 * 29) Comments should be generated for the accessors.
 * (REMOVED) 30) Comments should be generated for _Type too
 * 31) Comments on properties must be transfered to generated code
 * 32) Comments should be generated for the providers.
 * 33) Comments should be generated for the implementation fields.
 * 34) @_BeanInfo must be generated on the type
 * 35) Make sure inheritance work across file boundaries
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
class BeanProcessor extends Processor<InterfaceDeclaration,MutableInterfaceDeclaration> {
  static val char DOT = '.'
  static val NO_PARENTS = <BeanInfo>newArrayOfSize(0)
  static val NO_PROPERTIES = <PropertyInfo>newArrayOfSize(0)
  static val DUPLICATE = 'Duplicate simple name'
  static val BEAN_QUALIFIED_NAME = com.blockwithme.meta.beans.Bean.name
  static val ENTITY_QUALIFIED_NAME = Entity.name
  static val String BEAN_KEY = cacheKey(BEAN_QUALIFIED_NAME)
  static val String ENTITY_KEY = cacheKey(ENTITY_QUALIFIED_NAME)
  static val BP_HIERARCHY_ROOT = "BP_HIERARCHY_ROOT"

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
    super(and(isInterface,withAnnotation(Bean)))
  }

  /** Converts CamelCase to CAMEL_CASE */
  private static def String cameCaseToSnakeCase(String camelCase) {
    camelCase.replaceAll(
      String.format("%s|%s|%s",
        "(?<=[A-Z])(?=[A-Z][a-z])",
        "(?<=[^A-Z])(?=[A-Z])",
        "(?<=[A-Za-z])(?=[^A-Za-z])"
      ),
      "_"
    ).toUpperCase;
  }

  /** Capitalizes the first letter, taking "_" into account */
  private static def String to_FirstUpper(String str) {
    if (str.startsWith("_")) "_"+str.substring(1).toFirstUpper else str.toFirstUpper
  }

  /** Returns the Provider name */
  private def providerName(String pkgName, String simpleName) {
    pkgName+'.impl.'+simpleName+'Provider'
  }

  /** Returns the Property Accessor name */
  private def propertyAccessorName(String pkgName, String simpleName, String property) {
    val name = if (property.startsWith('_')) '_'+simpleName else simpleName
    pkgName+'.impl.'+name+to_FirstUpper(property)+'Accessor'
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

  /**
   * Each TypeDeclaration will be an interface, and it must be a @Bean,
   * or "empty", inclusive their parents. Otherwise, the first name
   * or a rejected type is returned.
   */
  private def String checkIsBeanOrMarker(Map<String,Object> processingContext, TypeDeclaration _interface) {
    if (isMarker(_interface)) {
      return null
    }
    if (accept(processingContext, _interface)) {
      for (parent : findParents(_interface)) {
        val parentResult = checkIsBeanOrMarker(processingContext, parent)
        if (parentResult !== null) {
          return parentResult
        }
      }
      return null
    }
    _interface.qualifiedName
  }

  /** Returns false if the given type name is not valid for a property */
  private def validPropertyType(Map<String,Object> processingContext, TypeReference typeRef, TypeDeclaration parent) {
    val name = ProcessorUtil.qualifiedName(typeRef)
    if (typeRef.array || typeRef.primitive || typeRef.wrapper
      || (typeRef == string) || (typeRef == classTypeRef)) {
      return true
    }
  	val allTypes = processingContext.get(PC_ALL_FILE_TYPES) as List<TypeDeclaration>
    var org.eclipse.xtend.lib.macro.declaration.Type type = allTypes.findFirst[it.qualifiedName == name]
    if (type === null) {
	    type = findTypeGlobally(name)
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
    	if (enumType.isAssignableFrom(type)) {
    		// Enum == Immutable!
    		return true
    	}
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
    var list = processingContext.get(noSameSimpleNameKey) as List
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
    val td = findTypeGlobally(qualifiedName)
    if (td === null) {
      // Unknown/undefined type (too early to query?)
      val result = new BeanInfo(qualifiedName,NO_PARENTS,NO_PROPERTIES,
        newArrayList("Undefined: "+qualifiedName), false, false, #[])
      result.check()
      val key = cacheKey(qualifiedName)
      val simpleName = qualifiedName.substring(qualifiedName.lastIndexOf(DOT)+1)
      val noSameSimpleNameKey = noSameSimpleNameKey(simpleName)
      putInCache(processingContext, key, noSameSimpleNameKey, result)
      return result
    }
    beanInfo(processingContext, findTypeGlobally(qualifiedName) as TypeDeclaration)
  }

  // STEP 1/2
  private def BeanInfo beanInfo(Map<String,Object> processingContext, TypeDeclaration td) {
    // Lazy init
    if (!processingContext.containsKey(BEAN_KEY)) {
      val b = new BeanInfo(BEAN_QUALIFIED_NAME,NO_PARENTS,NO_PROPERTIES, newArrayList(), true, false, #[])
      b.check()
      processingContext.put(BEAN_KEY, b)
      val bi = new BeanInfo(ENTITY_QUALIFIED_NAME,newArrayList(b),NO_PROPERTIES, newArrayList(), true, false, #[])
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
	  val isInstance = (bean !== null) && bean.getBooleanValue("instance")
      if (td instanceof TypeDeclaration) {
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
       }
      val check = checkIsBeanOrMarker(processingContext, td)
      if (check !== null) {
        // not valid as Bean/Marker type
        var msg = "Non Bean/Marker type: "+qualifiedName
        if (qualifiedName != check) {
          msg = msg + " because of "+check
        }
        result = new BeanInfo(qualifiedName,NO_PARENTS,NO_PROPERTIES,
          newArrayList(msg), false, isInstance, #[])
        result.check()
        putInCache(processingContext, key, noSameSimpleNameKey, result)
      } else {
        // Could be OK type ...
	    val String[] sortKeyes = if (bean !== null) bean.getStringArrayValue("sortKeyes") else #[]
        val parentsTD = findDirectParents(td)
        val fields = td.declaredFields
        // Add early in cache, to prevent infinite loops
        val parents = <BeanInfo>newArrayOfSize(parentsTD.size)
        val properties = <PropertyInfo>newArrayOfSize(fields.size)
        result = new BeanInfo(qualifiedName,parents,properties,
          newArrayList(), accept(processingContext, td), isInstance, sortKeyes)
        putInCache(processingContext, key, noSameSimpleNameKey, result)
        // Find parents
        var index = 0
        val parentFields = <String>newArrayList()
        for (p : parentsTD) {
          val b = beanInfo(processingContext, p)
          parents.set(index, b)
          index = index + 1
          if (!b.validity.isEmpty) {
            result.validity.add("Parent "+p.qualifiedName+" is not valid")
          }
          for (pp : b.properties) {
            requireNonNull(pp, b.qualifiedName+".properties[?]")
            requireNonNull(pp.name, b.qualifiedName+".properties[?].name")
            parentFields.add(pp.name.toLowerCase)
          }
        }
        // Find properties
        index = 0
        for (f : fields) {
          val ftypeName = f.type.name
          val doc = if (f.docComment === null) "" else f.docComment
      	  val unorderedSetAnnot = f.findAnnotation(findTypeGlobally(UnorderedSetProperty))
      	  val orderedSetAnnot = f.findAnnotation(findTypeGlobally(OrderedSetProperty))
      	  val sortedSetAnnot = f.findAnnotation(findTypeGlobally(SortedSetProperty))
      	  val listAnnot = f.findAnnotation(findTypeGlobally(ListProperty))
      	  val isCollProp = (unorderedSetAnnot !== null) || (orderedSetAnnot !== null)
      	  	|| (sortedSetAnnot !== null) || (listAnnot !== null)
      	  val virtualAnnot = f.findAnnotation(findTypeGlobally(VirtualProperty))
      	  var getterJavaCode = ""
      	  var setterJavaCode = ""
      	  if (virtualAnnot !== null) {
	      	  getterJavaCode = virtualAnnot.getStringValue("getterJavaCode")
	          requireNonNull(getterJavaCode, qualifiedName+"."+f.simpleName+".getterJavaCode")
	      	  setterJavaCode = virtualAnnot.getStringValue("setterJavaCode")
	          requireNonNull(setterJavaCode, qualifiedName+"."+f.simpleName+".setterJavaCode")
          }
          if (f.type.array) {
          	// A collection property!
          	val componentTypeName = f.type.arrayComponentType.name
          	val typeName = CollectionBean.name+"<"+componentTypeName+">"
          	var String collType = null
          	var fixedSize = -1
          	if (isCollProp) {
          		if (unorderedSetAnnot !== null) {
          			collType = CollectionPropertyType.unorderedSet
          		}
          		if (orderedSetAnnot !== null) {
          			if (collType !== null) {
          				throw new IllegalStateException(
          					"Multiple collection types used on "+qualifiedName+"."+f.simpleName)
          			}
          			collType = CollectionPropertyType.orderedSet
          		}
          		if (sortedSetAnnot !== null) {
          			if (collType !== null) {
          				throw new IllegalStateException(
          					"Multiple collection types used on "+qualifiedName+"."+f.simpleName)
          			}
          			collType = CollectionPropertyType.sortedSet
          		}
          		if (listAnnot !== null) {
          			if (collType !== null) {
          				throw new IllegalStateException(
          					"Multiple collection types used on "+qualifiedName+"."+f.simpleName)
          			}
          			collType = CollectionPropertyType.list
          			fixedSize = listAnnot.getIntValue("fixedSize")
      			}
          	}
            properties.set(index, new PropertyInfo(
	            requireNonNull(f.simpleName, "f.simpleName"),
	            requireNonNull(typeName, "typeName"), doc, collType, fixedSize,
	            getterJavaCode, setterJavaCode))
          } else {
          	  if (isCollProp) {
          		// NOT a collection property!
                result.validity.add("Property "+f.simpleName+" is not a collection type (must be array)")
          	  }
	          properties.set(index, new PropertyInfo(
	            requireNonNull(f.simpleName, "f.simpleName"),
	            requireNonNull(ftypeName, "ftypeName"),
	            doc, null, -1, getterJavaCode, setterJavaCode))
          }
          index = index + 1
          if (!validPropertyType(processingContext, f.type, td)) {
            result.validity.add("Property "+f.simpleName+" is not valid")
          }
          // STEP 4
          if (parentFields.contains(f.simpleName.toLowerCase)) {
            result.validity.add("Property "+f.simpleName
              +" is a duplicate from a parent property")
          }
        }
        // Find methods
        val methods = td.declaredMethods
        if (methods.iterator.hasNext) {
          result.validity.add("Has methods: "+methods.toList)
        }
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

  /** Adds Getters and Setter to the Bean Interface. */
  def private void processField(MutableFieldDeclaration fieldDeclaration,
      MutableInterfaceDeclaration interf) {
    val fieldName = fieldDeclaration.simpleName
    val toFirstUpper = to_FirstUpper(fieldName)
    val fieldType = fieldDeclaration.type
    val propertyType = if (fieldType.array) {
    	val componentType = fieldType.arrayComponentType
    	newTypeReference(CollectionBean, componentType)
    } else
    	fieldType
    val doc = if (fieldDeclaration.docComment != null) fieldDeclaration.docComment else "";

    val getter = 'get' + toFirstUpper
    if (interf.findDeclaredMethod(getter) === null) {
      interf.addMethod(getter) [
        returnType = propertyType
        // STEP 31
        // Comments on properties must be transfered to generated code
        if (doc.empty) {
          docComment = "Getter for "+fieldName
        } else {
          docComment = "Getter for "+doc
        }
      ]
      warn(BeanProcessor, "transform", interf, "Adding "+getter+" to "+interf.qualifiedName)
    }
    val setter = 'set' + toFirstUpper
    if (interf.findDeclaredMethod(setter, propertyType) === null) {
      interf.addMethod(setter) [
        addParameter(fieldName, propertyType)
        returnType = interf.newTypeReference
        // STEP 31
        // Comments on properties must be transfered to generated code
        if (doc.empty) {
          docComment = "Setter for "+fieldName
        } else {
          docComment = "Setter for "+doc
        }
      ]
      warn(BeanProcessor, "transform", interf, "Adding " + setter+" to "+interf.qualifiedName)
    }
    if (fieldType.array) {
	    val getter2 = 'getRaw' + toFirstUpper
	    if (interf.findDeclaredMethod(getter2) === null) {
	      interf.addMethod(getter2) [
	        returnType = propertyType
	        // STEP 31
	        // Comments on properties must be transfered to generated code
	        if (doc.empty) {
	          docComment = "Raw Getter for "+fieldName
	        } else {
	          docComment = "Raw Getter for "+doc
	        }
	      ]
	      warn(BeanProcessor, "transform", interf, "Adding "+getter2+" to "+interf.qualifiedName)
	    }
    }
    warn(BeanProcessor, "transform", interf, "Removing "+fieldName+" from "+interf.qualifiedName)
    fieldDeclaration.remove()
  }

  /** Returns the name of the hierarchy root of this interface. */
  private def String getHierarchyRoot(MutableInterfaceDeclaration mtd) {
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
				ProcessorUtil.qualifiedNames(roots as Iterable))
	}
	roots.get(0).qualifiedName
  }

  /** Adds the builder field */
  private def void addBuilderField(MutableInterfaceDeclaration meta, MutableInterfaceDeclaration mtd,
    Map<String,Object> processingContext) {
    val hierarchyRoot = getHierarchyRoot(mtd)
    if (hierarchyRoot === null) {
      error(BeanProcessor, "transform", meta, "Hierarchy Root of "+mtd.qualifiedName+" is null!")
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
      warn(BeanProcessor, "transform", meta, "Adding BUILDER to "+meta.qualifiedName)

      // First time we use Meta, so give is a comment:
      // STEP 28
      // Comments should be generated for Meta too
      meta.setDocComment("The Class Meta contains constants defining meta-information about types of this package.")
    } else {
      val currentRoot = processingContext.get(BP_HIERARCHY_ROOT)
      if ((currentRoot !==null) && (hierarchyRoot != currentRoot)) {
        error(BeanProcessor, "transform", meta,
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
      val bodyText = '''return instance.get«to_FirstUpper(propInfo.name)»();'''
      accessor.addMethod("apply") [
        visibility = Visibility.PUBLIC
        final = true
        static = false
        returnType = propTypeRef
        addParameter("instance", instanceType)
        body = [
          bodyText
        ]
        docComment = "Getter for the property "+qualifiedName+"."+propInfo.name
      ]
    }
    // Add setter
    val valueType = propTypeRef
    if (accessor.findDeclaredMethod("apply", instanceType, valueType) === null) {
      val bodyText = '''return instance.set«to_FirstUpper(propInfo.name)»(newValue);'''
      accessor.addMethod("apply") [
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
      ]
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
    cameCaseToSnakeCase(simpleName)+"_"+cameCaseToSnakeCase(propInfo.name)
  }

  /** Creates a Property constant in meta */
  private def String createPropertyConstant(MutableInterfaceDeclaration meta,
    BeanInfo beanInfo, String accessorName, PropertyInfo propInfo) {
    val metaPkg = BooleanProperty.package.name
    val propName = propertyMethodName(propInfo)
    val name = getPropertyFieldNameInMeta(beanInfo.simpleName, propInfo)
    val isVirtual = !propInfo.getterJavaCode.empty
    if (meta.findDeclaredField(name) === null) {
      val simpleName = beanInfo.simpleName
      val qualifiedName = beanInfo.pkgName+"."+simpleName
      val beanType = newTypeReference(qualifiedName)
      val TypeReference retTypeRef = if ("ObjectProperty" == propName) {
        newTypeReference(metaPkg+"."+propName, beanType, newTypeReferenceWithGenerics(propInfo.type))
      } else {
        newTypeReference(metaPkg+".True"+propName, beanType)
      }
      warn(BeanProcessor, "transform", meta, "Adding "+name+" to "+meta.qualifiedName)
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
  private def void createProvider(BeanInfo beanInfo) {
    val pkgName = beanInfo.pkgName
    val simpleName = beanInfo.simpleName
    val provider = getClass(providerName(pkgName, simpleName))
    warn(BeanProcessor, "transform", provider, "Implementing "+beanInfo.qualifiedName)
    val beanType = newTypeReference(beanInfo.qualifiedName)
    val providerIntf = newTypeReference(Provider, beanType)
    provider.setImplementedInterfaces(newArrayList(providerIntf))
    provider.visibility = Visibility.PUBLIC
    provider.final = true
    if (provider.findDeclaredMethod("get") === null) {
      val bodyText = '''return new «implName(pkgName, simpleName)»();'''
      provider.addMethod("get") [
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
      ]
    }
    // STEP 32
    // Comments should be generated for the providers.
    provider.docComment = "Provider for the type "+beanInfo.qualifiedName
  }

  /** Returns the code pointing to a Type instance, for the given BeanInfo */
  private def String beanInfoToTypeCode(BeanInfo beanInfo, String localPackage) {
    if (beanInfo.pkgName == localPackage) {
      cameCaseToSnakeCase(beanInfo.simpleName)
    } else if (beanInfo.isBean) {
      beanInfo.pkgName+".Meta."+cameCaseToSnakeCase(beanInfo.simpleName)
    } else {
      val java = JavaMeta.HIERARCHY.findType(beanInfo.qualifiedName)
      if (java !== null) {
        JavaMeta.name+"."+cameCaseToSnakeCase(java.simpleName)
      } else {
      	null
      }
    }
  }

  /** Adds the Type field */
  private def void addTypeField(MutableInterfaceDeclaration meta, BeanInfo beanInfo,
    String allProps) {
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
              warn(BeanProcessor, "transform", meta, msg)
            } else {
              error(BeanProcessor, "transform", meta, msg)
            }
      	} else {
          parents.append(parent)
          parents.append(', ')
      	}
      }
      if (parents.length > 0) {
        parents.length = parents.length - 2
      }
      val beanType = newTypeReference(beanInfo.qualifiedName)
      val props = if (allProps.empty) "" else ", "+allProps
      meta.addField(metaTypeFieldName(simpleName)) [
        visibility = Visibility.PUBLIC
        final = true
        static = true
        type = newTypeReference(Type, beanType)
        if (beanInfo.isInstance) {
	        initializer = [
	          '''BUILDER.newType(«simpleName».class, new «providerName(pkg, simpleName)»(), «Kind.name».Trait,
	          new Type[] {«parents»}«props»)'''
	        ]
        } else {
	        initializer = [
	          '''BUILDER.newType(«simpleName».class, null, «Kind.name».Trait,
	          new Type[] {«parents»}«props»)'''
	        ]
        }
        docComment = "Type field for "+beanInfo.qualifiedName
      ]
      warn(BeanProcessor, "transform", meta, "Adding "+cameCaseToSnakeCase(simpleName)+" to "+meta.qualifiedName)
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
//
//  /** Adds the Hierarchy */
//  private def void addHierarchyField(MutableInterfaceDeclaration meta, String pkgName) {
//    if (meta.findDeclaredField("HIERARCHY") === null) {
//      meta.addField("HIERARCHY") [
//        visibility = Visibility.PUBLIC
//        final = true
//        static = true
//        type = newTypeReference(Hierarchy)
//        initializer = [
//          '''BUILDER.newHierarchy(«packageFieldName(pkgName)»)'''
//        ]
//        docComment = "Hierarchy field for this package"
//      ]
//      warn(BeanProcessor, "transform", meta, "Adding HIERARCHY to "+meta.qualifiedName)
//    }
//  }

  /** Creates the implementation class for a type */
  private def MutableClassDeclaration createImplementation(Map<String,Object> processingContext, MutableInterfaceDeclaration mtd) {
    val qualifiedName = mtd.qualifiedName
    val index = qualifiedName.lastIndexOf(DOT)
    val pkgName = qualifiedName.substring(0,index)
    val simpleName = qualifiedName.substring(index+1)
    val implName = implName(pkgName, simpleName)
    val beanInfo = beanInfo(processingContext, mtd)
    val impl = getClass(implName)
    warn(BeanProcessor, "transform", impl, implName+" will be implemented")
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
    impl
  }

  /** Generates the field for the given property */
  private def void generatePropertyField(Map<String, Object> processingContext,
    MutableClassDeclaration impl, BeanInfo beanInfo, PropertyInfo propInfo) {
	val isVirtual = !propInfo.getterJavaCode.empty
    if (!isVirtual && impl.findDeclaredField(propInfo.name) === null) {
      val doc = propInfo.comment
      impl.addField(propInfo.name) [
        visibility = Visibility.PRIVATE
        final = false
        static = false
        type = newTypeReferenceWithGenerics(propInfo.type)
        // STEP 31
        // Comments on properties must be transfered to generated code
        if (doc.empty) {
          docComment = propInfo.name+" Field"
        } else {
          docComment = doc+" Field"
        }
      ]
      warn(BeanProcessor, "transform", impl, propInfo.name+" added to "+impl.qualifiedName)
    }
  }

	/** Generates the getter, setter for the given property */
	private def void generatePropertyMethods(Map<String, Object> processingContext,
		MutableClassDeclaration impl, BeanInfo beanInfo, PropertyInfo propInfo) {
		val propertyMethodName = propertyMethodName(propInfo);
		val propertyFieldName = beanInfo.pkgName+".Meta."+getPropertyFieldNameInMeta(beanInfo.simpleName, propInfo)
		val getterJavaCode = propInfo.getterJavaCode
		val setterJavaCode = propInfo.setterJavaCode
    	val isVirtual = !getterJavaCode.empty
		val doc = propInfo.comment
		val propTypeRef = newTypeReferenceWithGenerics(propInfo.type)
		val colType = propInfo.colType
		val tfu = to_FirstUpper(propInfo.name)
		val getter = if (colType !== null) "getRaw"+tfu else "get"+tfu
		if (impl.findDeclaredMethod(getter) === null) {
			val bodyText = if (isVirtual) getterJavaCode+";"
				else '''return interceptor.get«propertyMethodName»(this, «propertyFieldName», «propInfo.name»);'''
			impl.addMethod(getter) [
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
			]
			warn(BeanProcessor, "transform", impl, getter+" added to "+impl.qualifiedName)
		}
		val setter = "set"+tfu
		val valueType = propTypeRef
		if ((!isVirtual || !setterJavaCode.empty) && impl.findDeclaredMethod(setter, valueType) === null) {
			val bodyText = if (isVirtual) setterJavaCode+";"
				else '''«propInfo.name» = interceptor.set«propertyMethodName»(this, «propertyFieldName», «propInfo.name», newValue);
return this;'''
			impl.addMethod(setter) [
				visibility = Visibility.PUBLIC
				final = true
				static = false
				returnType = newTypeReference(impl.qualifiedName)
				addParameter("newValue", valueType)
				body = [
					bodyText
				]
				// STEP 31
				// Comments on properties must be transfered to generated code
				if (doc.empty) {
					docComment = "Setter for "+propInfo.name
				} else {
					docComment = "Setter for "+doc
				}
			]
			warn(BeanProcessor, "transform", impl, setter+" added to "+impl.qualifiedName)
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
					} else if (CollectionPropertyType.list == colType) {
						CollectionBeanConfig.name+".LIST"
					} else {
							throw new IllegalStateException(""+propInfo.colType)
					}
				}
      			val componentTypeType = beanInfoToTypeCode(beanInfo(processingContext, componentType), beanInfo.pkgName)
      			val componentTypeType2 = if (componentTypeType === null) {
      				error(BeanProcessor, "transform", impl, "Could not find Type for "+componentType)
      				"?"
      			} else {
      				componentTypeType
      			}
      			val bodyText = '''«propTypeRef» result = «getter»();
if (result == null) {
	«setter»(new «CollectionBeanImpl.name»<«componentType»>(«com.blockwithme.meta.beans.Meta.name».COLLECTION_BEAN, «componentTypeType2»,«config»));
	result = «getter»();
}
return result;'''
				impl.addMethod(creator) [
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
				]
				warn(BeanProcessor, "transform", impl, creator+" added to "+impl.qualifiedName)
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
					val props = <String>newArrayOfSize(beanInfo.properties.size*7)
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
						props.set(i, requireNonNull(p.getterJavaCode, p+": getterJavaCode"))
						i = i + 1
						props.set(i, requireNonNull(p.setterJavaCode, p+": setterJavaCode"))
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

		val parentList = <BeanInfo>newArrayList()
		for (p : _parents) {
			val qname = p.name
			if (!qname.contains('.')) {
				throw new IllegalStateException("Got a non-absolute type name: "+qname)
			}
			parentList.add(beanInfo(processingContext, qname))
		}

		val properties = <PropertyInfo>newArrayOfSize(_props.size/7)
		var i = 0
		while (i < _props.size) {
			val name = _props.get(i)
			val type = _props.get(i+1)
			val comment = _props.get(i+2)
			val colTypeName = _props.get(i+3)
			val colType = if (colTypeName.empty) null else colTypeName
			val fixedSize = Integer.parseInt(_props.get(i+4))
			val getterJavaCode = _props.get(i+5)
			val setterJavaCode = _props.get(i+6)
			properties.set(i/7, new PropertyInfo(name, type, comment, colType,
				fixedSize, getterJavaCode, setterJavaCode))
			i = i + 7
		}
		new BeanInfo(qualifiedName,
			parentList.toArray(newArrayOfSize(parentList.size)),
			properties,
			newArrayList(_validity),
			isBean, isInstance, sortKeyes)
	}

	/** Generates the "copy methods" */
	private def genCopyMethods(MutableInterfaceDeclaration mtd, MutableClassDeclaration impl) {
	    // STEP 37
	    // Generate the "copy methods" in the Type
		if (mtd.findDeclaredMethod("copy") === null) {
			mtd.addMethod("copy") [
				visibility = Visibility.PUBLIC
				final = false
				static = false
				returnType = newTypeReference(mtd)
				docComment = "Returns a full mutable copy"
			]
			warn(BeanProcessor, "transform", mtd, "copy() added to "+mtd.qualifiedName)
		}

		if (mtd.findDeclaredMethod("snapshot") === null) {
			mtd.addMethod("snapshot") [
				visibility = Visibility.PUBLIC
				final = false
				static = false
				returnType = newTypeReference(mtd)
				docComment = "Returns an immutable copy"
			]
			warn(BeanProcessor, "transform", mtd, "snapshot() added to "+mtd.qualifiedName)
		}

		if (mtd.findDeclaredMethod("wrapper") === null) {
			mtd.addMethod("wrapper") [
				visibility = Visibility.PUBLIC
				final = false
				static = false
				returnType = newTypeReference(mtd)
				docComment = "Returns a lightweight mutable copy"
			]
			warn(BeanProcessor, "transform", mtd, "wrapper() added to "+mtd.qualifiedName)
		}

		// STEP 38
		// Generate the "copy methods" in the implementation
		if (impl.findDeclaredMethod("copy") === null) {
			val bodyText = '''return («mtd.qualifiedName») doCopy();'''
			impl.addMethod("copy") [
				visibility = Visibility.PUBLIC
				final = false
				static = false
				returnType = newTypeReference(mtd)
				body = [
					bodyText
				]
				docComment = "Returns a full mutable copy"
			]
			warn(BeanProcessor, "transform", impl, "copy() added to "+impl.qualifiedName)
		}

		if (impl.findDeclaredMethod("snapshot") === null) {
			val bodyText = '''return («mtd.qualifiedName») doSnapshot();'''
			impl.addMethod("snapshot") [
				visibility = Visibility.PUBLIC
				final = false
				static = false
				returnType = newTypeReference(mtd)
				body = [
					bodyText
				]
				docComment = "Returns an immutable copy"
			]
			warn(BeanProcessor, "transform", impl, "snapshot() added to "+impl.qualifiedName)
		}

		if (impl.findDeclaredMethod("wrapper") === null) {
			val bodyText = '''return («mtd.qualifiedName») doWrapper();'''
			impl.addMethod("wrapper") [
				visibility = Visibility.PUBLIC
				final = false
				static = false
				returnType = newTypeReference(mtd)
				body = [
					bodyText
				]
				docComment = "Returns a lightweight mutable copy"
			]
			warn(BeanProcessor, "transform", impl, "wrapper() added to "+impl.qualifiedName)
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
							result = compare(get«to_FirstUpper(sortKey)»(), other.get«to_FirstUpper(sortKey)»());
						}
						«ENDFOR»
						return result;'''
				impl.addMethod("compareTo") [
					visibility = Visibility.PUBLIC
					final = false
					static = false
					addParameter("other", param)
					returnType = primitiveInt
					body = [
						bodyText
					]
					docComment = "Compares to other"
				]
				warn(BeanProcessor, "genCompareToMethods", impl, "compareTo(?) added to "+impl.qualifiedName)
			}
		}
	}

	/** Register new types, to be generated later. */
	override void register(Map<String,Object> processingContext, InterfaceDeclaration td,
		RegisterGlobalsContext context) {
		if (td !== null) {
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

				// STEP 9
				// Registering all Property Accessors, if needed
				for (p : beanInfo.properties) {
					registerClass(td, context, propertyAccessorName(pkgName, simpleName, p.name))
				}
			} else {
				error(BeanProcessor, "register", td, qualifiedName
					+" cannot be processed because: "+beanInfo.validity)
				for (p : beanInfo.parents) {
					if (!beanInfo.validity.empty) {
						error(BeanProcessor, "register", td, "... "+p.qualifiedName
							+" cannot be processed because: "+p.validity)
					}
				}
			}
		}
	}

	/** Transform types, new or old. */
	override void transform(Map<String,Object> processingContext, MutableInterfaceDeclaration mtd,
		TransformationContext context) {
		val beanInfo = beanInfo(processingContext, mtd)
		val qualifiedName = beanInfo.qualifiedName
		if (beanInfo.validity.empty) {
			warn(BeanProcessor, "transform", mtd, qualifiedName+" will be transformed")
			val pkgName = beanInfo.pkgName
			val simpleName = beanInfo.simpleName

			// STEP 10
			// The fields are replaced with getters and setters
			for (f : mtd.declaredFields.toList) {
				processField(f, mtd)
			}

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
				val name = createPropertyConstant(meta, beanInfo, accessorName, propInfo)
				allProps = if (allProps.empty) name else allProps+", "+name
			}

			// STEP 16
			// For each type, a type Provider under impl package is created.
			if (beanInfo.isInstance) {
				createProvider(beanInfo)
			}

			// STEP 17
			// For each type, following the properties, a type instance is created.
			addTypeField(meta, beanInfo, allProps)

			// STEP 21
			// The Impl extends either the impl of the first parent, or BaseImpl or EntityImpl appropriately
			val impl = createImplementation(processingContext, mtd)

			// STEP 22
			// For all getters and setters in type, implementations are generated in Impl
			for (propInfo : beanInfo.properties) {
				generatePropertyField(processingContext, impl, beanInfo, propInfo)
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
						generatePropertyField(processingContext, impl, bi, p)
					}
				}
			}

			// STEP 21
			// The Impl extends either the impl of the first parent, or BaseImpl or EntityImpl appropriately
			val typeTypeRef = newTypeReference(Type)
			if (impl.findDeclaredConstructor(typeTypeRef) === null) {
				impl.addConstructor[
					addParameter("metaType", typeTypeRef)
					visibility = Visibility.PROTECTED
					body = [
						'super(metaType);'
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

			// STEP 22
			// For all getters and setters in type, implementations are generated in Impl
			for (propInfo : beanInfo.properties) {
				generatePropertyMethods(processingContext, impl, beanInfo, propInfo)
			}

			// STEP 24
			// Add impl to all missing properties in Impl
			for (e : map.entrySet) {
				for (p : e.value) {
					generatePropertyMethods(processingContext, impl, e.key, p)
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
		} else {
			warn(BeanProcessor, "transform", mtd, qualifiedName
				+" will NOT be transformed, because: "+beanInfo.validity)
		}
		// else we already told the user mtd is bugged
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
//
//		// STEP 20
//		// After the package, the hierarchy is created.
//		addHierarchyField(meta, pkgName)
	}
}
