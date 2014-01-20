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
package com.blockwithme.meta

import static java.util.Objects.*
import static com.blockwithme.util.Preconditions.*
import static com.blockwithme.traits.util.SyncUtil.*
import java.util.Map
import org.slf4j.LoggerFactory
import java.util.List
import com.blockwithme.meta.converter.Converter

/**
 * HierarchyBuilder records the temporary information needed to construct
 * the MetaBase instances belonging to a Hierarchy.
 *
 * @author monster
 */
class HierarchyBuilder {

    static val LOG = LoggerFactory.getLogger(HierarchyBuilder);

    /** The Hierarchy name */
    public val String name

	/** All types of this hierarchy */
	package var Type<?>[] allTypes = <Type>newArrayOfSize(0)

	/** All properties of this hierarchy */
	package var Property<?,?>[] allProperties = <Property>newArrayOfSize(0)

	/** All packages of this hierarchy */
	package var TypePackage[] allPackages = <TypePackage>newArrayOfSize(0)

	/** Temporary storage for properties. */
	val Map<Class<?>,Map<String,Integer>> allCounters = newHashMap()

	/** The next global meta ID */
	var globalId = 0

	/** The next type ID */
	var typeId = 0

	/** The next property ID */
	var propertyId = 0

	/** The next package ID */
	var packageId = 0

	/** Are we done? */
	var closed = false

	/** Increments a counter, and returns the value before the increment. */
	protected def incCounter(Map<String,Integer> counters, String name) {
		var result = counters.get(name)
		if (result == null) {
			result = 0
		}
		counters.put(name, result + 1)
		result
	}

	/** Constructor */
	new(String theName) {
		name = requireNonEmpty(theName, "theName")
	}

	/** Constructor */
	new(Class<?> theRoot) {
		this(requireNonNull(theRoot, "theRoot").name)
	}

	/**
	 * Returns the pre-type-registration info
	 *
	 * DO NOT CALL DIRECTLY!
	 * This method is only public because it is called from a lambda.
	 */
	def doPreRegisterType(Class<?> theType) {
		if (allTypes.exists[t|t.type == theType]) {
			throw new IllegalArgumentException(theType+" already registered")
		}
		val result = new TypeRegistration
		result.builder = this
		result.globalId = globalId
		globalId = globalId + 1
		result.typeId = typeId
		typeId = typeId + 1
		LOG.debug("Type "+theType.name+" pre-registered in Hierarchy "+name)
		result
	}

	/**
	 * Registers a Type
	 *
	 * DO NOT CALL DIRECTLY!
	 * This method is only public because it is called from a lambda.
	 */
	def doRegisterType(Type<?> theType) {
		val list = newArrayList()
		list.addAll(allTypes as List<Type<?>>)
		val name = theType.type.name
		if (list.exists[t|(t != null) && t.fullName.equals(name)]) {
			throw new IllegalArgumentException(name+" already registered")
		}
		while (list.size <= theType.typeId) {
			list.add(null)
		}
		list.set(theType.typeId, theType)
		allTypes = list
		allCounters.remove(theType)
		LOG.info("Type "+theType.fullName+" registered in Hierarchy "+name)
		for (p : theType.properties) {
			doRegisterProperty(p)
		}
	}

	/**
	 * Creates and returns the property creation parameters
	 *
	 * DO NOT CALL DIRECTLY!
	 * This method is only public because it is called from a lambda.
	 */
	def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends Converter<PROPERTY_TYPE>>
	PropertyRegistration<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> doPreRegisterProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, PropertyType thePropType,
		int theBits, boolean theMeta, Type<PROPERTY_TYPE> dataType) {
		requireNonNull(theOwner, "theOwner")
		requireNonNull(theSimpleName, "theSimpleName")
		requireNonNull(theConverter, "theConverter")
		requireNonNull(thePropType, "thePropType")
		requireNonNull(dataType, "dataType")
		LOG.debug("Generating Property registration Data for "+theOwner.name
			+"."+theSimpleName+": "+thePropType+"/"+dataType+" in Hierarchy "+name)
		if (theConverter.type != dataType.type) {
			throw new IllegalArgumentException("theConverter.type("+theConverter.type
				+") must match dataType.type("+dataType.type+")")
		}
		var counters = allCounters.get(theOwner)
		if (counters == null) {
			counters = newHashMap()
			allCounters.put(theOwner, counters)
		}
		// This is only true, if the property is created right away...
		val globalId = this.globalId
		this.globalId = this.globalId + 1
		val globalPropertyId = this.propertyId
		this.propertyId = this.propertyId + 1

		val propertyId = incCounter(counters, "propertyId")
		val specificTypePropId = incCounter(counters, thePropType.name)
		// For primitive properties
		var primitivePropertyId = -1
		var nonSixtyFourBitPropertyId = -1
		var sixtyFourBitPropertyId = -1
		var nonLongPropertyId = -1
		var longOrObjectPropertyId = -1
		if (thePropType != PropertyType::OBJECT) {
			primitivePropertyId = incCounter(counters, "primitivePropertyId")
			if (theBits == 64) {
				sixtyFourBitPropertyId = incCounter(counters, "sixtyFourBitPropertyId")
			} else {
				nonSixtyFourBitPropertyId = incCounter(counters, "nonSixtyFourBitPropertyId")
			}
			if (thePropType != PropertyType::LONG) {
				nonLongPropertyId = incCounter(counters, "nonLongPropertyId")
			} else {
				longOrObjectPropertyId = incCounter(counters, "longOrObjectPropertyId")
			}
		} else {
			longOrObjectPropertyId = incCounter(counters, "longOrObjectPropertyId")
		}

		new PropertyRegistration<OWNER_TYPE, PROPERTY_TYPE, CONVERTER>(this, theOwner, theSimpleName,
			theConverter, thePropType, theMeta, dataType, globalId, globalPropertyId,
			propertyId, specificTypePropId, theBits, primitivePropertyId,
			nonSixtyFourBitPropertyId, sixtyFourBitPropertyId, nonLongPropertyId,
			longOrObjectPropertyId)
	}

	/**
	 * Registers a property.
	 *
	 * DO NOT CALL DIRECTLY!
	 * This method is only public because it is called from a lambda.
	 */
	def doRegisterProperty(Property<?,?> prop) {
		val list = <Property<?,?>>newArrayList()
		list.addAll(allProperties)
		val name = prop.fullName
		if (list.exists[p|(p != null) && p.fullName.equals(name)]) {
			throw new IllegalArgumentException(name+" already registered")
		}
		while (list.size <= prop.globalPropertyId) {
			list.add(null)
		}
		list.set(prop.globalPropertyId, prop)
		allProperties = list
		LOG.info("Property "+prop.fullName+" registered in Hierarchy "+name)
	}

	/**
	 * Returns the pre-package-registration info
	 *
	 * DO NOT CALL DIRECTLY!
	 * This method is only public because it is called from a lambda.
	 */
	def PackageRegistration doPreRegisterTypePackage(Type<?>[] theTypes) {
		val Class<?> clazz = getAnyPackageClass(theTypes)
		val result = new PackageRegistration
		result.builder = this
		result.globalId = globalId
		globalId = globalId + 1
		result.packageId = packageId
		packageId = packageId + 1
    	result.types = theTypes
		result.pkg = clazz.package
		result.name = getPackageName(clazz)
		val index = result.name.lastIndexOf('.')
		result.simpleName = if (index < 0) result.name else result.name.substring(index+1)
		result
	}

	/**
	 * Registers a Package
	 *
	 * DO NOT CALL DIRECTLY!
	 * This method is only public because it is called from a lambda.
	 */
	def void doRegisterTypePackage(TypePackage theTypePackage) {
		requireNonNull(theTypePackage, "theTypePackage")
		val list = newArrayList()
		list.addAll(allPackages as List<TypePackage>)
		val name = theTypePackage.fullName
		if (list.exists[t|(t != null) && t.fullName.equals(name)]) {
			throw new IllegalArgumentException(name+" already registered")
		}
		while (list.size <= theTypePackage.packageId) {
			list.add(null)
		}
		list.set(theTypePackage.packageId, theTypePackage)
		allPackages = list
		LOG.info("TypePackage "+theTypePackage.fullName+" registered in Hierarchy "+name)
		for (t : theTypePackage.types) {
			doRegisterType(t)
		}
	}

	/**
	 * Returns the first non-null class from the types.
	 * Fails if no such class exists.
	 */
	private static def getAnyPackageClass(Type<?>[] theTypes) {
		requireNonEmpty(theTypes, "theTypes")
		var Class<?> clazz = null
		for (t : theTypes) {
			if (t == null) {
				throw new IllegalArgumentException("theTypes contains null")
			}
			val c = t.type
			if (c != null) {
				if (clazz == null) {
					clazz = c
				} else if (clazz.package != c.package) {
					throw new IllegalArgumentException(
						"theTypes are using multiple packages (for example: "
						+clazz+" and "+c)
				}
			}
		}
		if (clazz == null) {
			throw new IllegalArgumentException("no class found in theTypes")
		}
		clazz
	}

	package def void checkNotClosed() {
		if (closed) {
			throw new IllegalStateException("closed")
		}
	}

	/** Extracts the package name (because I had some issues with Xtend about this) */
	private static def getPackageName(Class<?> theClass) {
		requireNonNull(theClass, "theClass")
		val name = theClass.name
		val index = name.lastIndexOf('.')
		if (index < 0) name else name.substring(0,index)
	}


	/** Returns the pre-type-registration info */
	def preRegisterType(Class<?> theType) {
		synchR(this) [
			it.checkNotClosed()
			it.doPreRegisterType(theType)
		]
	}

	/** Creates and returns the property creation parameters */
	def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends Converter<PROPERTY_TYPE>>
	PropertyRegistration<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> preRegisterProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, PropertyType thePropType,
		int theBits, boolean theMeta, Type<PROPERTY_TYPE> dataType) {
		synchR(this) [
			it.checkNotClosed()
			it.doPreRegisterProperty(theOwner, theSimpleName, theConverter,
				thePropType, theBits, theMeta, dataType)
		]
	}

	/** Creates and returns the property creation parameters (and computes meta flag) */
	def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends Converter<PROPERTY_TYPE>>
	PropertyRegistration<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> preRegisterProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, PropertyType thePropType,
		int theBits, Type<PROPERTY_TYPE> dataType) {
		var _meta = false
		for (t : Types.META.allTypes) {
			if (theOwner == t.type) {
				_meta = true
			}
		}
		preRegisterProperty(theOwner, theSimpleName, theConverter, thePropType, theBits, _meta, dataType)
	}

	/** Registers a property */
	def registerMetaProperty(MetaProperty<?,?> prop) {
		synch(this) [
			it.checkNotClosed()
			it.doRegisterProperty(prop)
		]
	}

	/** Returns the pre-package-registration info */
	def preRegisterPackage(Type<?>[] theTypes) {
		synchR(this) [
			it.checkNotClosed()
			it.doPreRegisterTypePackage(theTypes)
		]
	}

	/** Registers a Package */
	def registerPackage(TypePackage ... theTypePackages) {
		synch(this) [
			it.checkNotClosed()
			for (p : theTypePackages) {
				it.doRegisterTypePackage(p)
			}
		]
		theTypePackages
	}

	/** All types of this hierarchy */
	def allTypes() {
		synchR(this) [
			requireContainsNoNull(allTypes, "allTypes")
		]
	}

	/** All properties of this hierarchy */
	def allProperties() {
		synchR(this) [
			requireContainsNoNull(allProperties, "allProperties")
		]
	}

	/** All packages of this hierarchy */
	def allPackages() {
		synchR(this) [
			requireContainsNoNull(allPackages, "allPackages")
		]
	}

	def close() {
		synch(this) [
			closed = true
		]
	}
}