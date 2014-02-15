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

import java.lang.annotation.ElementType
import java.lang.annotation.Inherited
import java.lang.annotation.Retention
import java.lang.annotation.RetentionPolicy
import java.lang.annotation.Target
import java.util.HashMap
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.RegisterGlobalsContext
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableInterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeDeclaration
import java.util.List
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import com.blockwithme.meta.beans.Entity
import org.eclipse.xtend.lib.macro.declaration.MutableFieldDeclaration
import org.eclipse.xtend.lib.macro.declaration.Visibility
import com.blockwithme.meta.HierarchyBuilder
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import com.blockwithme.meta.BooleanPropertyAccessor
import com.blockwithme.meta.BooleanProperty
import javax.inject.Provider
import java.util.Map
import com.blockwithme.meta.TypePackage
import com.blockwithme.meta.JavaMeta
import java.util.Set
import java.util.HashSet
import com.blockwithme.meta.Hierarchy
import com.blockwithme.meta.beans.impl._EntityImpl
import com.blockwithme.meta.beans.impl._BeanImpl

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
}

@Data
package class PropertyInfo {
	String name
	String type
}

@Data
package class BeanInfo {
	String qualifiedName
	BeanInfo[] parents
	PropertyInfo[] properties
	List<String> validity
	boolean isBean
	Map<BeanInfo,PropertyInfo[]> _allProperties
	def pkgName() {
		qualifiedName.substring(0,qualifiedName.lastIndexOf('.'))
	}
	def simpleName() {
		qualifiedName.substring(qualifiedName.lastIndexOf('.')+1)
	}
	// STEP 21
	// If we have more then one parent, find out all missing properties
	def Map<BeanInfo,PropertyInfo[]> allProperties() {
		if (_allProperties.empty) {
			_allProperties.put(this, properties)
			for (p : parents) {
				_allProperties.putAll(p.allProperties)
			}
		}
		_allProperties
	}
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
 * 8) For each type, the internal API interface (_X) is registered, if not defined yet
 * 9) For each type property, an Accessor type under impl package is declared, if not defined yet
 * GENERATE:
 * 10) For each type, the fields are replaced with getters and setters
 * 11) A builder is created in Meta for that package
 * 12) For each type property, a property accessor class is generated
 * 13) For each type property, a property object in the "Meta" interface is generated.
 * 14) For each type, a type Provider under impl package is created.
 * 15) For each type, following the properties, a type instance is created.
 * 16) After all types, a package meta-object is created.
 * 17) The list of dependencies for the Hierarchy is computed.
 * 18) After the package, the hierarchy is created.
 * 19) The Impl extends either the impl of the first parent, or BaseImpl or EntityImpl appropriately
 * 20) For all getters and setters in type, implementations are generated in Impl
 * 21) If we have more then one parent, find out all missing properties
 * 22) Add impl to all missing properties in Impl
 *
 * @author monster
 */
class BeanProcessor extends Processor<InterfaceDeclaration,MutableInterfaceDeclaration> {
	static val char DOT = '.'
	static val NO_PARENTS = <BeanInfo>newArrayOfSize(0)
	static val NO_PROPERTIES = <PropertyInfo>newArrayOfSize(0)
	static val DUPLICATE = 'Duplicate simple name'
	static val BP_ALL_DEPENDENCIES = 'BP_ALL_DEPENDENCIES'

	/** The "transient" cache */
	static var CACHE = new HashMap<String,Object>

	/** Public constructor for this class. */
	new() {
		// Step 0, make sure we have an interface, annotated with @Bean
		super(and(isInterface,withAnnotation(Bean)))
		var qualifiedName = com.blockwithme.meta.beans.Bean.name
		var key = cacheKey(qualifiedName)
		val b = new BeanInfo(qualifiedName,NO_PARENTS,NO_PROPERTIES, newArrayList(), true, new HashMap)
		CACHE.put(key, b)
		qualifiedName = Entity.name
		key = cacheKey(qualifiedName)
		CACHE.put(key, new BeanInfo(qualifiedName,newArrayList(b),NO_PROPERTIES, newArrayList(), true, new HashMap))
	}

	/** Returns the internal API name */
	private def internalName(String pkgName, String simpleName) {
		pkgName+'._'+simpleName
	}

	/** Returns the internal API name */
	private def internalName(InterfaceDeclaration td) {
		val qualifiedName = td.qualifiedName
		val index = qualifiedName.lastIndexOf(DOT)
		val pkgName = qualifiedName.substring(0,index)
		val simpleName = qualifiedName.substring(index+1)
		internalName(pkgName, simpleName)
	}

	/** Returns the Provider name */
	private def providerName(String pkgName, String simpleName) {
		pkgName+'.impl.'+simpleName+'Provider'
	}

	/** Returns the Property Accessor name */
	private def propertyAccessorName(String pkgName, String simpleName, String property) {
		pkgName+'.impl.'+simpleName+property.toFirstUpper+'Accessor'
	}

	/** Returns the Provider name */
	private def providerName(InterfaceDeclaration td) {
		val qualifiedName = td.qualifiedName
		val index = qualifiedName.lastIndexOf(DOT)
		val pkgName = qualifiedName.substring(0,index)
		val simpleName = qualifiedName.substring(index+1)
		providerName(pkgName, simpleName)
	}

	/** Returns the implementation name */
	private def implName(String pkgName, String simpleName) {
		pkgName+'.impl.'+simpleName+'Impl'
	}

	/** Returns the implementation name */
	private def implName(InterfaceDeclaration td) {
		val qualifiedName = td.qualifiedName
		val index = qualifiedName.lastIndexOf(DOT)
		val pkgName = qualifiedName.substring(0,index)
		val simpleName = qualifiedName.substring(index+1)
		implName(pkgName, simpleName)
	}

	/** Returns the meta name */
	private def metaName(String pkgName, String simpleName) {
		pkgName+'.Meta'
	}

	/** Returns the meta name */
	private def metaName(InterfaceDeclaration td) {
		val qualifiedName = td.qualifiedName
		val index = qualifiedName.lastIndexOf(DOT)
		val pkgName = qualifiedName.substring(0,index)
		val simpleName = qualifiedName.substring(index+1)
		metaName(pkgName, simpleName)
	}

	/** *Safely* registers an interface */
	private def registerInterface(InterfaceDeclaration td, RegisterGlobalsContext context, String name) {
		if (findTypeGlobally(name) === null) {
			context.registerInterface(name)
			warn(TraitProcessor, "register", td, "Registering Interface: "+name)
		}
	}

	/** *Safely* registers a class */
	private def registerClass(InterfaceDeclaration td, RegisterGlobalsContext context, String name) {
		if (findTypeGlobally(name) === null) {
			context.registerClass(name)
			warn(TraitProcessor, "register", td, "Registering Class: "+name)
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
	private def validPropertyType(Map<String,Object> processingContext, TypeReference typeRef) {
		val name = ProcessorUtil.qualifiedName(typeRef)
		val allDependencies = getAllDependencies(processingContext)
		val java = JavaMeta.HIERARCHY.findType(name)
		if (java !== null) {
			allDependencies.add(JavaMeta.name+".HIERARCHY")
		}
		if (typeRef.array || typeRef.primitive || typeRef.wrapper
			|| (typeRef == string) || (typeRef == classTypeRef)) {
			return true
		}
		val type = findTypeGlobally(name)
		if ((type !== null) && findTypeGlobally(Bean).isAssignableFrom(type)) {
			val dot = name.lastIndexOf(DOT)
			allDependencies.add(name.substring(0, dot)+".Meta.HIERARCHY")
			return true
		}
		if (type instanceof TypeDeclaration) {
			val bi = beanInfo(processingContext, type)
			if ((bi !== null) && bi.validity.empty) {
				return true
			}
		}
		// TODO Allow user-defined immutable types too
		false
	}

	private def cacheKey(String qualifiedName) {
		"BeanInfo:"+qualifiedName
	}

	private def noSameSimpleNameKey(String simpleName) {
		"noSameSimpleNameKey:"+simpleName.toLowerCase
	}

	private def putInCache(String key, String noSameSimpleNameKey, BeanInfo beanInfo) {
		CACHE.put(key, beanInfo)
		var list = CACHE.get(noSameSimpleNameKey) as List
		if (list === null) {
			list = newArrayList()
			CACHE.put(noSameSimpleNameKey, list)
			list.add(beanInfo)
		} else {
			list.add(beanInfo)
			// STEP 3 (we do not change the validity of pre-exiting, now-invalid, types
			val validity = beanInfo.validity
			if (!validity.contains(DUPLICATE)) {
				validity.add(DUPLICATE)
			}
		}
	}

	// STEP 1/2
	/** Scans the Type hierarchy for compatibility */
	private def BeanInfo beanInfo(Map<String,Object> processingContext, TypeDeclaration td) {
		val qualifiedName = td.qualifiedName
		val simpleName = td.simpleName
		val key = cacheKey(qualifiedName)
		val noSameSimpleNameKey = noSameSimpleNameKey(simpleName)
		var result = CACHE.get(key) as BeanInfo
		if (result === null) {
			val type = findTypeGlobally(qualifiedName)
			if (type === null) {
				// Unknown/undefined type (too early to query?)
				result = new BeanInfo(qualifiedName,NO_PARENTS,NO_PROPERTIES,
					newArrayList("Undefined: "+qualifiedName), false, new HashMap)
				putInCache(key, noSameSimpleNameKey, result)
			} else {
				val check = checkIsBeanOrMarker(processingContext, td)
				if (check !== null) {
					// not valid as Bean/Marker type
					var msg = "Non Bean/Marker type: "+qualifiedName
					if (qualifiedName != check) {
						msg = msg + " because of "+check
					}
					result = new BeanInfo(qualifiedName,NO_PARENTS,NO_PROPERTIES,
						newArrayList(msg), false, new HashMap)
					putInCache(key, noSameSimpleNameKey, result)
				} else {
					// Could be OK type ...
					val parentsTD = findParents(td)
					val fields = td.declaredFields
					// Add early in cache, to prevent infinite loops
					val parents = <BeanInfo>newArrayOfSize(parentsTD.size)
					val properties = <PropertyInfo>newArrayOfSize(fields.size)
					result = new BeanInfo(qualifiedName,parents,properties,
						newArrayList(), accept(processingContext, td), new HashMap)
					putInCache(key, noSameSimpleNameKey, result)
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
							parentFields.add(pp.name.toLowerCase)
						}
					}
					// Find properties
					index = 0
					for (f : fields) {
						val ftypeName = f.type.name
						properties.set(index, new PropertyInfo(f.simpleName, ftypeName))
						index = index + 1
						if (!validPropertyType(processingContext, f.type)) {
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
				}
			}
		}
		result
	}

	/** Adds Getters and Setter to the Bean Interface. */
	def private void processField(MutableFieldDeclaration fieldDeclaration,
			MutableInterfaceDeclaration interf) {
		val fieldName = fieldDeclaration.simpleName
		val toFirstUpper = fieldName.toFirstUpper
		val fieldType = fieldDeclaration.type

		// TODO Move _name to the "internal interface"
		val getter = 'get' + toFirstUpper
		interf.addMethod(getter) [
			returnType = fieldType
		]
		interf.addMethod('set' + toFirstUpper) [
			addParameter(fieldName, fieldType)
			returnType = interf.newTypeReference
		]
//		if (fieldType.array) {
//			interf.addMethod('get' + toFirstUpper) [
//				addParameter('index', primitiveInt)
//				returnType = fieldType.arrayComponentType
//			]
//			interf.addMethod('set' + toFirstUpper) [
//				addParameter('index', primitiveInt)
//				addParameter(fieldName, fieldType.arrayComponentType)
//				returnType = interf.newTypeReference
//			]
//		} else if (fieldType.isList) {
//			interf.addMethod('get' + toFirstUpper) [
//				addParameter('index', primitiveInt)
//				returnType = fieldType.actualTypeArguments.head ?: getObject()
//			]
//			interf.addMethod('set' + toFirstUpper) [
//				val tp = fieldType.actualTypeArguments.head ?: getObject()
//				addParameter('index', primitiveInt)
//				addParameter(fieldName, tp)
//				returnType = interf.newTypeReference
//			]
//		}
		fieldDeclaration.remove()
	}

	/** Adds the builder field */
	private def void addBuilderField(MutableClassDeclaration meta, String pkgName) {
		// Only define once!
		if (meta.findDeclaredField("BUILDER") === null) {
			// public static final BUILDER = new HierarchyBuilder(Object);
			meta.addField("BUILDER") [
				visibility = Visibility.PUBLIC
				final = true
				static = true
				type = newTypeReference(HierarchyBuilder)
				initializer = [
					'''new «HierarchyBuilder.name»("«pkgName»")'''
				]
			]
		}
	}

	/** Implements the required Property accessor interface */
	private def String implementPropertyAccessor(BeanInfo beanInfo, PropertyInfo propInfo) {
		val pkgName = beanInfo.pkgName
		val simpleName = beanInfo.simpleName
		val accessorName = propertyAccessorName(pkgName, simpleName, propInfo.name)
		val accessor = findClass(accessorName)
		val propType = propInfo.type
		// Make accessor extend <Type>PropertyAccessor
		val propertyAccessorPrefix = switch (propType) {
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
		val pkg = BooleanPropertyAccessor.package.name
		val propertyAccessorIntf = newTypeReference(pkg+'.'+propertyAccessorPrefix+"PropertyAccessor")
		accessor.setImplementedInterfaces(newArrayList(propertyAccessorIntf))
		accessor.visibility = Visibility.PUBLIC
		accessor.final = true
		// Add getter
		accessor.addMethod("apply") [
			visibility = Visibility.PUBLIC
			final = true
			static = false
			returnType = newTypeReference(propType)
			val getterInstanceType = newTypeReference(beanInfo.qualifiedName)
			addParameter("instance", getterInstanceType)
			body = [
				'''return instance.get«propInfo.name.toFirstUpper»();'''
			]
		]
		// Add setter
		accessor.addMethod("apply") [
			visibility = Visibility.PUBLIC
			final = true
			static = false
			returnType = newTypeReference(beanInfo.qualifiedName)
			val getterInstanceType = newTypeReference(beanInfo.qualifiedName)
			addParameter("instance", getterInstanceType)
			addParameter("newValue", newTypeReference(propType))
			body = [
				'''return instance.set«propInfo.name.toFirstUpper»(newValue);'''
			]
		]
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
		simpleName.toUpperCase+"_"+propInfo.name.toUpperCase
	}

	/** Creates a Property constant in meta */
	private def String createPropertyConstant(MutableClassDeclaration meta,
		String simpleName, String accessorName, PropertyInfo propInfo) {
		val metaPkg = BooleanProperty.package.name
		val propName = propertyMethodName(propInfo)
		val name = getPropertyFieldNameInMeta(simpleName, propInfo)
		meta.addField(name) [
			visibility = Visibility.PUBLIC
			final = true
			static = true
			type = newTypeReference(metaPkg+".True"+propName)
			initializer = [
				'''BUILDER.new«propName»(«simpleName».class, «propInfo.name», new «accessorName»())'''
			]
		]
		name
	}

	/** Crate a Provider for a type */
	private def void createProvider(BeanInfo beanInfo) {
		val pkgName = beanInfo.pkgName
		val simpleName = beanInfo.simpleName
		val provider = findClass(providerName(pkgName, simpleName))
		val providerIntf = newTypeReference(Provider)
		provider.setImplementedInterfaces(newArrayList(providerIntf))
		provider.visibility = Visibility.PUBLIC
		provider.final = true
		provider.addMethod("get") [
			visibility = Visibility.PUBLIC
			final = true
			static = false
			returnType = newTypeReference(beanInfo.qualifiedName)
			body = [
				'''return new «implName(pkgName, simpleName)»();'''
			]
		]
	}

	/** Adds the Type field */
	private def void addTypeField(MutableClassDeclaration meta, BeanInfo beanInfo,
		String allProps, Set<String> allDependencies) {
		val pkg = beanInfo.pkgName
		val simpleName = beanInfo.simpleName
		val parents = new StringBuilder
		for (p : beanInfo.parents) {
			if (p.pkgName == pkg) {
				parents.append(p.simpleName.toUpperCase)
				parents.append(', ')
			} else if (p.isBean) {
				parents.append(p.pkgName+".Meta."+p.simpleName.toUpperCase)
				parents.append(', ')
				allDependencies.add(p.pkgName+".Meta.HIERARCHY")
			} else {
				val java = JavaMeta.HIERARCHY.findType(p.qualifiedName)
				if (java !== null) {
					parents.append(JavaMeta.name+"."+java.simpleName.toUpperCase)
					parents.append(', ')
					allDependencies.add(JavaMeta.name+".HIERARCHY")
				} else {
					val msg = p.qualifiedName+" unknown; not adding as parent of "
						+beanInfo.qualifiedName
					val pTD = findTypeGlobally(p.qualifiedName)
					if ((pTD !== null) && isMarker(pTD)) {
						warn(BeanProcessor, "transform", meta, msg)
					} else {
						error(BeanProcessor, "transform", meta, msg)
					}
				}
			}
		}
		meta.addField(simpleName.toUpperCase) [
			visibility = Visibility.PUBLIC
			final = true
			static = true
			type = newTypeReference(com.blockwithme.meta.Type)
			initializer = [
				'''BUILDER.newType(«simpleName».class, new «providerName(pkg, simpleName)», Kind.Trait,
				«parents», «allProps»)'''
			]
		]
	}

	/** Returns the name of the package field */
	private def String packageFieldName(String pkgName) {
		pkgName.replace(DOT, '_').toUpperCase+"_PACKAGE"
	}

	/** Adds the package */
	private def void addPackageField(MutableClassDeclaration meta, List<TypeDeclaration> allTypes,
		String pkgName) {
		val allTypesStr = allTypes.join(', ') [
			simpleName.toUpperCase
		]
		meta.addField(packageFieldName(pkgName)) [
			visibility = Visibility.PUBLIC
			final = true
			static = true
			type = newTypeReference(TypePackage)
			initializer = [
				'''BUILDER.newTypePackage(«allTypesStr»)'''
			]
		]
	}

	/** Returns the hierarchy dependencies */
	private def Set<String> getAllDependencies(Map<String,Object> processingContext) {
		// STEP 17
		// The list of dependencies for the Hierarchy is computed.
		var result = processingContext.get(BP_ALL_DEPENDENCIES) as Set<String>
		if (result === null) {
			result = new HashSet<String>
			processingContext.put(BP_ALL_DEPENDENCIES, result)
		}
		result
	}

	/** Adds the Hierarchy */
	private def void addHierarchyField(MutableClassDeclaration meta,
		String pkgName, Set<String> allDependencies) {
		meta.addField("HIERARCHY") [
			visibility = Visibility.PUBLIC
			final = true
			static = true
			type = newTypeReference(Hierarchy)
			initializer = [
				if (allDependencies.empty) {
					'''BUILDER.newHierarchy(«packageFieldName(pkgName)»)'''
				} else {
					'''BUILDER.newHierarchy(«packageFieldName(pkgName)», «allDependencies.join(', ')»)'''
				}
			]
		]
	}

	/** Creates the implementation class for a type */
	private def MutableClassDeclaration createImplementation(Map<String,Object> processingContext, MutableInterfaceDeclaration mtd) {
		val qualifiedName = mtd.qualifiedName
		val index = qualifiedName.lastIndexOf(DOT)
		val pkgName = qualifiedName.substring(0,index)
		val simpleName = qualifiedName.substring(index+1)
		val implName = implName(pkgName, simpleName)
		val beanInfo = beanInfo(processingContext, mtd)
		val impl = findClass(implName)
		val first = beanInfo.parents.head()
		val entity = findTypeGlobally(Entity)
		if ((first !== null) && first.isBean) {
			val parentName = implName(first.pkgName, first.simpleName)
			impl.setExtendedClass(newTypeReference(parentName))
		} else if (entity.isAssignableFrom(mtd)) {
			impl.setExtendedClass(newTypeReference(_EntityImpl))
		} else {
			impl.setExtendedClass(newTypeReference(_BeanImpl))
		}
		impl.setImplementedInterfaces(newArrayList(
			newTypeReference(qualifiedName), newTypeReference(internalName(pkgName, simpleName))))
		impl
	}

	/** Generates the getter, setter and field for the given property */
	private def void generateProperty(Map<String, Object> processingContext,
		MutableClassDeclaration impl, BeanInfo beanInfo, PropertyInfo propInfo) {
		impl.addField(propInfo.name) [
			visibility = Visibility.PRIVATE
			final = false
			static = false
			type = newTypeReference(propInfo.type)
		]
		val propertyMethodName = propertyMethodName(propInfo);
		val propertyFieldName = beanInfo.pkgName+".Meta."+getPropertyFieldNameInMeta(beanInfo.simpleName, propInfo)
		impl.addMethod("get"+propInfo.name.toFirstUpper) [
			visibility = Visibility.PUBLIC
			final = true
			static = false
			returnType = newTypeReference(propInfo.type)
			body = [
				'''return interceptor.get«propertyMethodName»(this, «propertyFieldName», «propInfo.name»);'''
			]
		]
		impl.addMethod("set"+propInfo.name.toFirstUpper) [
			visibility = Visibility.PUBLIC
			final = true
			static = false
			returnType = newTypeReference(beanInfo.qualifiedName)
			addParameter("$newValue", newTypeReference(propInfo.type))
			body = [
				'''«propInfo.name» = interceptor.set«propertyMethodName»(this, «propertyFieldName», «propInfo.name», $newValue);
				return this;'''
			]
		]
	}

	/** Register new types, to be generated later. */
	override void register(Map<String,Object> processingContext, InterfaceDeclaration td, RegisterGlobalsContext context) {
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
			registerClass(td, context, providerName(pkgName, simpleName))

			// STEP 7
			// Registering the Meta, if needed
			registerInterface(td, context, metaName(pkgName, simpleName))

			// STEP 8
			// Registering the internal API interface, if needed
			registerInterface(td, context, internalName(pkgName, simpleName))

			// STEP 9
			// Registering all Property Accessors, if needed
			for (p : beanInfo.properties) {
				registerClass(td, context, propertyAccessorName(pkgName, simpleName, p.name))
			}
		} else {
			error(BeanProcessor, "register", td, qualifiedName
				+" cannot be processed because: "+beanInfo.validity)
		}
	}

	/** Transform types, new or old. */
	override void transform(Map<String,Object> processingContext, MutableInterfaceDeclaration mtd, TransformationContext context) {
		val beanInfo = beanInfo(processingContext, mtd)
		if (beanInfo.validity.empty) {
			val pkgName = beanInfo.pkgName
			val simpleName = beanInfo.simpleName

			// STEP 10
			// The fields are replaced with getters and setters
			for (f : mtd.declaredFields.toList) {
				processField(f, mtd)
			}

			// STEP 11
			// A builder is created in Meta for that package
			val meta = findClass(metaName(pkgName, simpleName))
			addBuilderField(meta, pkgName)

			// STEP 12
			// For each type property, a property accessor class is generated
			var allProps = ""
			for (propInfo : beanInfo.properties) {
				val accessorName = implementPropertyAccessor(beanInfo, propInfo)
				// STEP 13
				// For each type property, a property object in the "Meta" interface is generated.
				val name = createPropertyConstant(meta, simpleName, accessorName, propInfo)
				allProps = if (allProps.empty) name else allProps+", "+name
			}

			// STEP 14
			// For each type, a type Provider under impl package is created.
			createProvider(beanInfo)

			// STEP 15
			// For each type, following the properties, a type instance is created.
			val allDependencies = getAllDependencies(processingContext)
			addTypeField(meta, beanInfo, allProps, allDependencies)

			// Post-type-processing phases
			val allDone = (processingContext.get(PC_TODO_TYPES) as List<?>).empty
			if (allDone) {
				// STEP 16
				// After all types, a package meta-object is created.
				val allTypes = processingContext.get(PC_TODO_TYPES) as List<TypeDeclaration>
				addPackageField(meta, allTypes, pkgName)

				// (Just to be safe, remove ourselves from the dependencies)
				allDependencies.remove(pkgName+".Meta.HIERARCHY")

				// STEP 18
				// After the package, the hierarchy is created.
				addHierarchyField(meta, pkgName, allDependencies)
			}

			// STEP 19
			// The Impl extends either the impl of the first parent, or BaseImpl or EntityImpl appropriately
			val impl = createImplementation(processingContext, mtd)

			// STEP 20
			// For all getters and setters in type, implementations are generated in Impl
			for (propInfo : beanInfo.properties) {
				generateProperty(processingContext, impl, beanInfo, propInfo)
			}

			// STEP 22
			// Add impl to all missing properties in Impl
			var firstParent = beanInfo.parents.head()
			if ((firstParent !== null) && !firstParent.isBean) {
				firstParent = null
			}
			for (e : beanInfo.allProperties.entrySet) {
				val key = e.key
				if ((key !== beanInfo) && ((firstParent === null) || !firstParent.allProperties.containsKey(key))) {
					// Missing properties!
					for (p : e.value) {
						generateProperty(processingContext, impl, key, p)
					}
				}
			}
		}
		// else we already told the user mtd is bugged
	}
}
