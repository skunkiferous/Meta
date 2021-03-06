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
import static com.blockwithme.util.shared.Preconditions.*
import static extension com.blockwithme.util.xtend.StdExt.*
import java.util.Map
import java.util.logging.Logger
import java.util.List
import com.blockwithme.util.shared.converters.Converter
import com.blockwithme.fn1.BooleanFuncObject
import com.blockwithme.fn2.ObjectFuncObjectBoolean
import com.blockwithme.fn1.ByteFuncObject
import com.blockwithme.fn2.ObjectFuncObjectByte
import com.blockwithme.fn1.CharFuncObject
import com.blockwithme.fn2.ObjectFuncObjectChar
import com.blockwithme.fn1.FloatFuncObject
import com.blockwithme.fn2.ObjectFuncObjectFloat
import com.blockwithme.fn1.IntFuncObject
import com.blockwithme.fn2.ObjectFuncObjectInt
import com.blockwithme.fn1.ShortFuncObject
import com.blockwithme.fn2.ObjectFuncObjectShort
import com.blockwithme.fn1.DoubleFuncObject
import com.blockwithme.fn2.ObjectFuncObjectDouble
import com.blockwithme.fn1.LongFuncObject
import com.blockwithme.fn2.ObjectFuncObjectLong
import com.blockwithme.fn1.ObjectFuncObject
import com.blockwithme.fn2.ObjectFuncObjectObject
import com.blockwithme.util.shared.converters.IntConverter
import com.blockwithme.util.shared.converters.BooleanConverter
import com.blockwithme.util.shared.converters.ByteConverter
import com.blockwithme.util.shared.converters.CharConverter
import com.blockwithme.util.shared.converters.ShortConverter
import com.blockwithme.util.shared.converters.FloatConverter
import com.blockwithme.util.shared.converters.DoubleConverter
import com.blockwithme.util.shared.converters.LongConverter
import javax.inject.Provider
import com.blockwithme.util.shared.converters.ObjectConverter
import com.blockwithme.util.base.SystemUtils

/**
 * HierarchyBuilder records the temporary information needed to construct
 * the MetaBase instances belonging to a Hierarchy.
 *
 * @author monster
 */
class HierarchyBuilder {

    static val LOG = Logger.getLogger(HierarchyBuilder.name);

    static val char DOT = "."

    static val ObjectProperty[] NO_OBJECT_PROP = newArrayOfSize(0)

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

	/** The next meta property ID */
	var metaPropertyId = 0

	/** The next package ID */
	var packageId = 0

	/** Are we done? */
	var closed = false

	/** The Hierarchy; the HierarchyBuilder is closed after creating it. */
	var Hierarchy _hierarchy = null

	/** Increments a counter, and returns the value before the increment. */
	protected static def incCounter(Map<String,Integer> counters, String name) {
		var result = counters.get(name)
		if (result == null) {
			result = 0
		}
		counters.put(name, result + 1)
		result
	}

	/** Constructor. Takes the hierarchy name as parameter. */
	new(String theName) {
		name = requireNonEmpty(theName, "theName")
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
		LOG.warn("Type "+theType.name+" pre-registered in Hierarchy "+name+" with typeId "+result.typeId)
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
		LOG.info("Type "+theType.fullName+" registered in Hierarchy "+this.name)
		for (p : theType.properties) {
			doRegisterProperty(p)
		}
		for (p : theType.virtualProperties) {
			doRegisterProperty(p)
		}
	}

	/**
	 * Creates and returns the property creation parameters
	 *
	 * DO NOT CALL DIRECTLY!
	 * This method is only public because it is called from a lambda.
	 */
	def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends Converter<?,PROPERTY_TYPE>>
	PropertyRegistration<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> doPreRegisterProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, PropertyType thePropType,
		int theBits, boolean theMeta, Class<PROPERTY_TYPE> dataType, boolean theVirtual) {
		requireNonNull(theOwner, "theOwner")
		requireNonNull(theSimpleName, "theSimpleName")
		requireNonNull(theConverter, "theConverter")
		requireNonNull(thePropType, "thePropType")
		requireNonNull(dataType, "dataType")
		LOG.debug("Generating Property registration Data for "+theOwner.name
			+"."+theSimpleName+": "+thePropType+"/"+dataType+" in Hierarchy "+name)
		if (theConverter.type != dataType) {
			throw new IllegalArgumentException("theConverter.type("+theConverter.type
				+") must match dataType.type("+dataType+")")
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
		val globalMetaPropertyId = if (theMeta) {
			this.metaPropertyId = this.metaPropertyId + 1
			this.metaPropertyId - 1
		} else {
			-1
		}

		val propertyId = incCounter(counters, "propertyId")
		var specificTypePropId = -1
		// For primitive properties
		var primitivePropertyId = -1
		var nonSixtyFourBitPropertyId = -1
		var sixtyFourBitPropertyId = -1
		var nonLongPropertyId = -1
		var longOrObjectPropertyId = -1
		var virtualPropertyId = -1

		if (theVirtual) {
			virtualPropertyId = incCounter(counters, "virtualPropertyId")
		} else if (counters.get("virtualPropertyId") !== null) {
			throw new IllegalStateException(
			"Cannot declare non-virtual property after a virtual property in "+theOwner)
		} else {
			specificTypePropId = incCounter(counters, thePropType.name)
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
		}

		LOG.debug("PROPERTY "+theSimpleName+" OF "+name+" IS GETTING GLOBAL PROPERTY ID "+globalPropertyId)
		new PropertyRegistration<OWNER_TYPE, PROPERTY_TYPE, CONVERTER>(this, theOwner, theSimpleName,
			theConverter, thePropType, theMeta, theVirtual, dataType, globalId, globalPropertyId,
			globalMetaPropertyId, propertyId, specificTypePropId, virtualPropertyId, theBits,
			primitivePropertyId, nonSixtyFourBitPropertyId, sixtyFourBitPropertyId, nonLongPropertyId,
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
		if (list.exists[p|(p != null) && (p.fullName == name)]) {
			throw new IllegalArgumentException(name+" already registered")
		}
		while (list.size <= prop.globalPropertyId) {
			list.add(null)
		}
		list.set(prop.globalPropertyId, prop)
		allProperties = list
		LOG.info("Property "+prop.fullName+" with ID "+prop.globalPropertyId+" registered in Hierarchy "+this.name)
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
		val other = list.findFirst[t|(t != null) && t.fullName.equals(name)]
		if (other !== null) {
			if (other === theTypePackage) {
				LOG.warn("TypePackage "+theTypePackage.fullName
					+" ALREADY registered in Hierarchy "+this.name)
				return
			}
			throw new IllegalArgumentException(name+" already registered")
		}
		while (list.size <= theTypePackage.packageId) {
			list.add(null)
		}
		list.set(theTypePackage.packageId, theTypePackage)
		allPackages = list
		LOG.info("TypePackage "+theTypePackage.fullName+" registered in Hierarchy "+this.name)
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
				} else if (getPackageName(clazz) != getPackageName(c)) {
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
		val name2 = if (index < 0) name else name.substring(0,index)
		if (name2.startsWith("[L")) name2.substring(2) else name2
	}


	/** Returns the pre-type-registration info */
	synchronized final def preRegisterType(Class<?> theType) {
		checkNotClosed()
		doPreRegisterType(theType)
	}

	/** Creates and returns the property creation parameters */
	synchronized final def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends Converter<?,PROPERTY_TYPE>>
	PropertyRegistration<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> preRegisterProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, PropertyType thePropType,
		int theBits, boolean theMeta, Class<PROPERTY_TYPE> dataType, boolean theVirtual) {
		checkNotClosed()
		doPreRegisterProperty(theOwner, theSimpleName, theConverter,
			thePropType, theBits, theMeta, dataType, theVirtual)
	}

	/** Creates and returns the property creation parameters (and computes meta flag) */
	def final <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends Converter<?,PROPERTY_TYPE>>
	PropertyRegistration<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> preRegisterProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, PropertyType thePropType,
		int theBits, Class<PROPERTY_TYPE> dataType, boolean theVirtual) {
		val _meta = MetaBase.isAssignableFrom(theOwner)
		preRegisterProperty(theOwner, theSimpleName, theConverter, thePropType,
			theBits, _meta, dataType, theVirtual)
	}

	/** Registers a property */
	synchronized final def registerMetaProperty(MetaProperty<?,?> prop) {
		checkNotClosed()
		doRegisterProperty(prop)
	}

	/** Returns the pre-package-registration info */
	synchronized final def preRegisterPackage(Type<?>[] theTypes) {
		checkNotClosed()
		doPreRegisterTypePackage(theTypes)
	}

	/** Registers a Package */
	synchronized final def registerPackage(TypePackage ... theTypePackages) {
		checkNotClosed()
		for (p : theTypePackages) {
			doRegisterTypePackage(p)
		}
		theTypePackages
	}

	/** All types of this hierarchy */
	synchronized final def allTypes() {
		requireContainsNoNull(allTypes, name+".allTypes")
	}

	/** All properties of this hierarchy */
	synchronized final def allProperties() {
		requireContainsNoNull(allProperties, name+".allProperties")
	}

	/** All packages of this hierarchy */
	synchronized final def allPackages() {
		requireContainsNoNull(allPackages, name+".allPackages")
	}

	/** We're done! */
	synchronized final def close() {
		closed = true
	}

	/* Helper method, to completely hide the implementation of interfaces */
	def <JAVA_TYPE> Provider<JAVA_TYPE> createProvider(Class<JAVA_TYPE> interfaze) {
		val pkg = requireNonNull(interfaze, "interfaze").package.name
		val name = interfaze.simpleName
		val providerName = pkg+".impl."+name+"ImplProvider"
		SystemUtils.newInstance(SystemUtils.forName(providerName)) as Provider<JAVA_TYPE>
	}

	// Now comes the factory methods

	/** Creates a Boolean Property */
	def <OWNER_TYPE> TrueBooleanProperty<OWNER_TYPE> newBooleanProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		BooleanFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectBoolean<OWNER_TYPE,OWNER_TYPE> theSetter, boolean theVirtual) {
		new TrueBooleanProperty<OWNER_TYPE>(this, theOwner, theSimpleName, theGetter, theSetter, theVirtual)
	}

	/** Creates a Boolean Property */
	final def <OWNER_TYPE> TrueBooleanProperty<OWNER_TYPE> newBooleanProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		BooleanPropertyAccessor<OWNER_TYPE> theAccessor, boolean theVirtual) {
		newBooleanProperty(theOwner, theSimpleName, theAccessor, theAccessor, theVirtual)
	}

	/** Creates a Boolean Property */
	final def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends BooleanConverter<OWNER_TYPE, PROPERTY_TYPE>>
		BooleanProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> newBooleanProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, Class<PROPERTY_TYPE> dataType,
		BooleanPropertyAccessor<OWNER_TYPE> theAccessor, boolean theVirtual) {
		newBooleanProperty(theOwner, theSimpleName, theConverter, dataType,
			theAccessor, theAccessor, theVirtual)
	}

	/** Creates a Boolean Property */
	def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends BooleanConverter<OWNER_TYPE, PROPERTY_TYPE>>
		BooleanProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> newBooleanProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, Class<PROPERTY_TYPE> dataType,
		BooleanFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectBoolean<OWNER_TYPE,OWNER_TYPE> theSetter, boolean theVirtual) {
		new BooleanProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER>(
			this, theOwner, theSimpleName, theConverter, dataType,
			theGetter, theSetter, theVirtual)
	}

	/** Creates a Byte Property */
	def <OWNER_TYPE> TrueByteProperty<OWNER_TYPE> newByteProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		ByteFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectByte<OWNER_TYPE,OWNER_TYPE> theSetter, boolean theVirtual) {
		new TrueByteProperty<OWNER_TYPE>(this, theOwner, theSimpleName, theGetter, theSetter, theVirtual)
	}

	/** Creates a Byte Property */
	final def <OWNER_TYPE> TrueByteProperty<OWNER_TYPE> newByteProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		BytePropertyAccessor<OWNER_TYPE> theAccessor, boolean theVirtual) {
		newByteProperty(theOwner, theSimpleName, theAccessor, theAccessor, theVirtual)
	}

	/** Creates a Byte Property */
	final def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends ByteConverter<OWNER_TYPE, PROPERTY_TYPE>>
		ByteProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> newByteProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, int theBits, Class<PROPERTY_TYPE> dataType,
		BytePropertyAccessor<OWNER_TYPE> theAccessor, boolean theVirtual) {
		newByteProperty(theOwner, theSimpleName, theConverter, theBits, dataType,
			theAccessor, theAccessor, theVirtual)
	}

	/** Creates a Byte Property */
	def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends ByteConverter<OWNER_TYPE, PROPERTY_TYPE>>
		ByteProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> newByteProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, int theBits, Class<PROPERTY_TYPE> dataType,
		ByteFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectByte<OWNER_TYPE,OWNER_TYPE> theSetter, boolean theVirtual) {
		new ByteProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER>(
			this, theOwner, theSimpleName, theConverter, theBits, dataType,
			theGetter, theSetter, theVirtual)
	}

	/** Creates a Character Property */
	def <OWNER_TYPE> TrueCharacterProperty<OWNER_TYPE> newCharacterProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CharFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectChar<OWNER_TYPE,OWNER_TYPE> theSetter, boolean theVirtual) {
		new TrueCharacterProperty<OWNER_TYPE>(this, theOwner, theSimpleName, theGetter, theSetter, theVirtual)
	}

	/** Creates a Character Property */
	final def <OWNER_TYPE> TrueCharacterProperty<OWNER_TYPE> newCharacterProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CharPropertyAccessor<OWNER_TYPE> theAccessor, boolean theVirtual) {
		newCharacterProperty(theOwner, theSimpleName, theAccessor, theAccessor, theVirtual)
	}

	/** Creates a Character Property */
	final def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends CharConverter<OWNER_TYPE, PROPERTY_TYPE>>
		CharacterProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> newCharacterProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, int theBits, Class<PROPERTY_TYPE> dataType,
		CharPropertyAccessor<OWNER_TYPE> theAccessor, boolean theVirtual) {
		newCharacterProperty(theOwner, theSimpleName, theConverter, theBits, dataType,
			theAccessor, theAccessor, theVirtual)
	}

	/** Creates a Character Property */
	def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends CharConverter<OWNER_TYPE, PROPERTY_TYPE>>
		CharacterProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> newCharacterProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, int theBits, Class<PROPERTY_TYPE> dataType,
		CharFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectChar<OWNER_TYPE,OWNER_TYPE> theSetter, boolean theVirtual) {
		new CharacterProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER>(
			this, theOwner, theSimpleName, theConverter, theBits, dataType,
			theGetter, theSetter, theVirtual)
	}

	/** Creates a Short Property */
	def <OWNER_TYPE> TrueShortProperty<OWNER_TYPE> newShortProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		ShortFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectShort<OWNER_TYPE,OWNER_TYPE> theSetter, boolean theVirtual) {
		new TrueShortProperty<OWNER_TYPE>(this, theOwner, theSimpleName, theGetter, theSetter, theVirtual)
	}

	/** Creates a Short Property */
	final def <OWNER_TYPE> TrueShortProperty<OWNER_TYPE> newShortProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		ShortPropertyAccessor<OWNER_TYPE> theAccessor, boolean theVirtual) {
		newShortProperty(theOwner, theSimpleName, theAccessor, theAccessor, theVirtual)
	}

	/** Creates a Short Property */
	final def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends ShortConverter<OWNER_TYPE, PROPERTY_TYPE>>
		ShortProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> newShortProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, int theBits, Class<PROPERTY_TYPE> dataType,
		ShortPropertyAccessor<OWNER_TYPE> theAccessor, boolean theVirtual) {
		newShortProperty(theOwner, theSimpleName, theConverter, theBits, dataType,
			theAccessor, theAccessor, theVirtual)
	}

	/** Creates a Short Property */
	def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends ShortConverter<OWNER_TYPE, PROPERTY_TYPE>>
		ShortProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> newShortProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, int theBits, Class<PROPERTY_TYPE> dataType,
		ShortFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectShort<OWNER_TYPE,OWNER_TYPE> theSetter, boolean theVirtual) {
		new ShortProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER>(
			this, theOwner, theSimpleName, theConverter, theBits, dataType,
			theGetter, theSetter, theVirtual)
	}

	/** Creates a Float Property */
	def <OWNER_TYPE> TrueFloatProperty<OWNER_TYPE> newFloatProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		FloatFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectFloat<OWNER_TYPE,OWNER_TYPE> theSetter, boolean theVirtual) {
		new TrueFloatProperty<OWNER_TYPE>(this, theOwner, theSimpleName, theGetter, theSetter, theVirtual)
	}

	/** Creates a Float Property */
	def <OWNER_TYPE> TrueFloatProperty<OWNER_TYPE> newFloatProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		FloatPropertyAccessor<OWNER_TYPE> theAccessor, boolean theVirtual) {
		newFloatProperty(theOwner, theSimpleName, theAccessor, theAccessor, theVirtual)
	}

	/** Creates a Float Property */
	final def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends FloatConverter<OWNER_TYPE, PROPERTY_TYPE>>
		FloatProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> newFloatProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, Class<PROPERTY_TYPE> dataType,
		FloatPropertyAccessor<OWNER_TYPE> theAccessor, boolean theVirtual) {
		newFloatProperty(theOwner, theSimpleName, theConverter, dataType,
			theAccessor, theAccessor, theVirtual)
	}

	/** Creates a Float Property */
	def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends FloatConverter<OWNER_TYPE, PROPERTY_TYPE>>
		FloatProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> newFloatProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, Class<PROPERTY_TYPE> dataType,
		FloatFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectFloat<OWNER_TYPE,OWNER_TYPE> theSetter, boolean theVirtual) {
		new FloatProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER>(
			this, theOwner, theSimpleName, theConverter, dataType,
			theGetter, theSetter, theVirtual)
	}

	/** Creates a Integer Property */
	def <OWNER_TYPE> TrueIntegerProperty<OWNER_TYPE> newIntegerProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		IntFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectInt<OWNER_TYPE,OWNER_TYPE> theSetter, boolean theVirtual) {
		new TrueIntegerProperty<OWNER_TYPE>(this, theOwner, theSimpleName, theGetter, theSetter, theVirtual)
	}

	/** Creates a Integer Property */
	final def <OWNER_TYPE> TrueIntegerProperty<OWNER_TYPE> newIntegerProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		IntPropertyAccessor<OWNER_TYPE> theAccessor, boolean theVirtual) {
		newIntegerProperty(theOwner, theSimpleName, theAccessor, theAccessor, theVirtual)
	}

	/** Creates a Integer Property */
	final def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends IntConverter<OWNER_TYPE, PROPERTY_TYPE>>
		IntegerProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> newIntegerProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, int theBits, Class<PROPERTY_TYPE> dataType,
		IntPropertyAccessor<OWNER_TYPE> theAccessor, boolean theVirtual) {
		newIntegerProperty(theOwner, theSimpleName, theConverter, theBits, dataType,
			theAccessor, theAccessor, theVirtual)
	}

	/** Creates a Integer Property */
	def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends IntConverter<OWNER_TYPE, PROPERTY_TYPE>>
		IntegerProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> newIntegerProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, int theBits, Class<PROPERTY_TYPE> dataType,
		IntFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectInt<OWNER_TYPE,OWNER_TYPE> theSetter, boolean theVirtual) {
		new IntegerProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER>(
			this, theOwner, theSimpleName, theConverter, theBits, dataType,
			theGetter, theSetter, theVirtual)
	}

	/** Creates a Double Property */
	def <OWNER_TYPE> TrueDoubleProperty<OWNER_TYPE> newDoubleProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		DoubleFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectDouble<OWNER_TYPE,OWNER_TYPE> theSetter, boolean theVirtual) {
		new TrueDoubleProperty<OWNER_TYPE>(this, theOwner, theSimpleName, theGetter, theSetter, theVirtual)
	}

	/** Creates a Double Property */
	final def <OWNER_TYPE> TrueDoubleProperty<OWNER_TYPE> newDoubleProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		DoublePropertyAccessor<OWNER_TYPE> theAccessor, boolean theVirtual) {
		newDoubleProperty(theOwner, theSimpleName, theAccessor, theAccessor, theVirtual)
	}

	/** Creates a Double Property */
	final def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends DoubleConverter<OWNER_TYPE, PROPERTY_TYPE>>
		DoubleProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> newDoubleProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, Class<PROPERTY_TYPE> dataType,
		DoublePropertyAccessor<OWNER_TYPE> theAccessor, boolean theVirtual) {
		newDoubleProperty(theOwner, theSimpleName, theConverter, dataType,
			theAccessor, theAccessor, theVirtual)
	}

	/** Creates a Double Property */
	def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends DoubleConverter<OWNER_TYPE, PROPERTY_TYPE>>
		DoubleProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> newDoubleProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, Class<PROPERTY_TYPE> dataType,
		DoubleFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectDouble<OWNER_TYPE,OWNER_TYPE> theSetter, boolean theVirtual) {
		new DoubleProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER>(
			this, theOwner, theSimpleName, theConverter, dataType,
			theGetter, theSetter, theVirtual)
	}

	/** Creates a Long Property */
	def <OWNER_TYPE> TrueLongProperty<OWNER_TYPE> newLongProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		LongFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectLong<OWNER_TYPE,OWNER_TYPE> theSetter, boolean theVirtual) {
		new TrueLongProperty<OWNER_TYPE>(this, theOwner, theSimpleName, theGetter, theSetter, theVirtual)
	}

	/** Creates a Long Property */
	final def <OWNER_TYPE> TrueLongProperty<OWNER_TYPE> newLongProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		LongPropertyAccessor<OWNER_TYPE> theAccessor, boolean theVirtual) {
		newLongProperty(theOwner, theSimpleName, theAccessor, theAccessor, theVirtual)
	}

	/** Creates a Long Property */
	final def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends LongConverter<OWNER_TYPE, PROPERTY_TYPE>>
		LongProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> newLongProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, int theBits, Class<PROPERTY_TYPE> dataType,
		LongPropertyAccessor<OWNER_TYPE> theAccessor, boolean theVirtual) {
		newLongProperty(theOwner, theSimpleName, theConverter, theBits, dataType,
			theAccessor, theAccessor, theVirtual)
	}

	/** Creates a Long Property */
	def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends LongConverter<OWNER_TYPE, PROPERTY_TYPE>>
		LongProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> newLongProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, int theBits, Class<PROPERTY_TYPE> dataType,
		LongFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectLong<OWNER_TYPE,OWNER_TYPE> theSetter, boolean theVirtual) {
		new LongProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER>(
			this, theOwner, theSimpleName, theConverter, theBits, dataType,
			theGetter, theSetter, theVirtual)
	}

	/** Creates a Object Property */
	final def <OWNER_TYPE, PROPERTY_TYPE> ObjectProperty<OWNER_TYPE, PROPERTY_TYPE, PROPERTY_TYPE,
	? extends ObjectConverter<OWNER_TYPE, PROPERTY_TYPE, PROPERTY_TYPE>> newObjectProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		Class<?> theContentType, boolean theShared, boolean theActualInstance,
		boolean theExactType, boolean theNullAllowed, ObjectFuncObject<PROPERTY_TYPE,OWNER_TYPE> theGetter,
		ObjectFuncObjectObject<OWNER_TYPE,OWNER_TYPE,PROPERTY_TYPE> theSetter, boolean theVirtual) {
		// theContentType is not typesafe on purpose, as this makes the code
		// generation much easier for object properties
		newObjectProperty(theOwner, theSimpleName,
			null, theContentType as Class<PROPERTY_TYPE>, theShared, theActualInstance, theExactType,
			theNullAllowed, theGetter, theSetter, theVirtual)
	}

	/** Creates a Object Property */
	final def <OWNER_TYPE, PROPERTY_TYPE> ObjectProperty<OWNER_TYPE, PROPERTY_TYPE, PROPERTY_TYPE,
	? extends ObjectConverter<OWNER_TYPE, PROPERTY_TYPE, PROPERTY_TYPE>> newObjectProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		Class<?> theContentType, boolean theShared, boolean theActualInstance,
		boolean theExactType, boolean theNullAllowed,
		ObjectPropertyAccessor<OWNER_TYPE,PROPERTY_TYPE> theAccessor, boolean theVirtual) {
		// theContentType is not typesafe on purpose, as this makes the code
		// generation much easier for object properties
		newObjectProperty(theOwner, theSimpleName,
			null, theContentType as Class<PROPERTY_TYPE>, theShared, theActualInstance, theExactType,
			theNullAllowed, theAccessor, theAccessor, theVirtual)
	}

	/** Creates a Object Property */
	def <OWNER_TYPE, PROPERTY_TYPE, INTERNAL_TYPE,
		CONVERTER extends ObjectConverter<OWNER_TYPE, PROPERTY_TYPE, INTERNAL_TYPE>>
		ObjectProperty<OWNER_TYPE, PROPERTY_TYPE, INTERNAL_TYPE, CONVERTER> newObjectProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName, CONVERTER theConverter,
		Class<?> theContentType, boolean theShared, boolean theActualInstance,
		boolean theExactType, boolean theNullAllowed, ObjectFuncObject<PROPERTY_TYPE,OWNER_TYPE> theGetter,
		ObjectFuncObjectObject<OWNER_TYPE,OWNER_TYPE,PROPERTY_TYPE> theSetter, boolean theVirtual) {
		// theContentType is not typesafe on purpose, as this makes the code
		// generation much easier for object properties
		new ObjectProperty<OWNER_TYPE, PROPERTY_TYPE, INTERNAL_TYPE, CONVERTER>(this, theOwner, theSimpleName,
			theConverter, theContentType as Class<PROPERTY_TYPE>, theShared, theActualInstance, theExactType,
			theNullAllowed, theGetter, theSetter, theVirtual)
	}

	/** Creates a Object Property */
	final def <OWNER_TYPE, PROPERTY_TYPE, INTERNAL_TYPE,
		CONVERTER extends ObjectConverter<OWNER_TYPE, PROPERTY_TYPE, INTERNAL_TYPE>>
		ObjectProperty<OWNER_TYPE, PROPERTY_TYPE, INTERNAL_TYPE, CONVERTER> newObjectProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName, CONVERTER theConverter,
		Class<?> theContentType, boolean theShared, boolean theActualInstance,
		boolean theExactType, boolean theNullAllowed,
		ObjectPropertyAccessor<OWNER_TYPE,PROPERTY_TYPE> theAccessor, boolean theVirtual) {
		// theContentType is not typesafe on purpose, as this makes the code
		// generation much easier for object properties
		newObjectProperty(theOwner, theSimpleName,
			theConverter, theContentType as Class<PROPERTY_TYPE>, theShared, theActualInstance, theExactType,
			theNullAllowed, theAccessor, theAccessor, theVirtual)
	}

	/** Creates a new Type */
	final def <JAVA_TYPE> Type<JAVA_TYPE> newType(Class<JAVA_TYPE> theType,
		Provider<JAVA_TYPE> theConstructor, Kind theKind,
		ValidatorsMap validatorsMap, ListenersMap listenersMap,
		Property<JAVA_TYPE,?> ... theProperties) {
		newType(theType, theConstructor, theKind, validatorsMap, listenersMap, Type.NO_TYPE, theProperties, NO_OBJECT_PROP)
	}

	/** Creates a new Type with parents */
	final def <JAVA_TYPE> Type<JAVA_TYPE> newType(Class<JAVA_TYPE> theType,
		Provider<JAVA_TYPE> theConstructor, Kind theKind,
		ValidatorsMap validatorsMap, ListenersMap listenersMap,
		Type<?>[] theParents, Property<JAVA_TYPE,?> ... theProperties) {
		newType(theType, theConstructor, theKind, validatorsMap, listenersMap, theParents, theProperties, NO_OBJECT_PROP)
	}

	/** Creates a new Type with parents and component types */
	def <JAVA_TYPE> Type<JAVA_TYPE> newType(Class<JAVA_TYPE> theType,
		Provider<JAVA_TYPE> theConstructor, Kind theKind,
		ValidatorsMap validatorsMap, ListenersMap listenersMap,
		Type<?>[] theParents, Property<JAVA_TYPE,?>[] theProperties,
		ObjectProperty<JAVA_TYPE,Type<?>,?,?> ... theComponents) {
		new Type(preRegisterType(theType), theType, theConstructor, theKind,
			validatorsMap, listenersMap, theParents, theProperties, theComponents)
	}

	/** Creates a new TypePackage */
	def TypePackage newTypePackage(Type<?> ... theTypes) {
		new TypePackage(this, theTypes)
	}

	/** Searches for all dependencies */
	private def Hierarchy[] findDependencies(TypePackage[] packages) {
		val pkgAsList = <String>newArrayList(packages.map[it.fullName])
		for (p : JavaMeta.HIERARCHY.allPackages) {
			pkgAsList.add(p.fullName)
		}
		val result = <Hierarchy>newArrayList()
		result.add(JavaMeta.HIERARCHY)
		for (pkg : packages) {
			for (t : pkg.types) {
				for (prop : t.properties) {
					// contentTypeClass does not require having initialized the hierarchy
					val typeName = prop.contentTypeClass.name
					val dot = typeName.lastIndexOf(DOT)
					if (dot > 0) {
						val pkgName = typeName.substring(0, dot)
						if (!pkgAsList.contains(pkgName)) {
							// Force initialization of Meta...
							try {
								SystemUtils.forName(pkgName+".Meta").declaredFields
							} catch (Throwable ex) {
								// NOP
								ex.printStackTrace
							}
							try {
								// Not part of our packages, so a dependency
								val h = prop.contentType.hierarchy()
								if ((h !== null) && !result.contains(h)) {
									result.add(h)
								}
							} catch (RuntimeException ex) {
								val type = HierarchyBuilderFactory.findType(prop.contentTypeClass)
								if (type !== null) {
									val h = type.hierarchy()
									if (h === null) {
										throw new RuntimeException("For contentType "+typeName
											+" property: "+prop+" packages: "+pkgAsList, ex)
									}
									if ((h !== null) && !result.contains(h)) {
										result.add(h)
									}
								} else {
									throw new RuntimeException("For contentType "+typeName
										+" property: "+prop+" packages: "+pkgAsList, ex)
								}
							}
						}
					}
				}
			}
		}
		result
	}

	/** Creates a new Hierarchy */
	protected def Hierarchy newHierarchy(TypePackage[] thePackages, Hierarchy[] theDependencies) {
		new Hierarchy(this, thePackages, theDependencies)
	}

	/** Creates a new Hierarchy */
	final def Hierarchy newHierarchy(TypePackage... packages) {
		val registered = registerPackage(packages)
		val dependencies = if ((Object.name == name) || (class == MetaHierarchyBuilder)) newArrayOfSize(0) else findDependencies(registered)
		_hierarchy = newHierarchy(registered, dependencies)
		close()
		for (pkg : registered) {
			for (type : pkg.types) {
				for (prop : type.allProperties) {
					if ((prop.contentTypeClass !== null)
						&& !prop.contentTypeClass.array) {
						try {
							val h = prop.contentType.hierarchy()
							if ((h !== _hierarchy) && !dependencies.contains(h)) {
								LOG.error("Property "+prop.fullName+" has contentType "
									+prop.contentType.fullName+" which is not part of "+type.fullName
									+" Hierarchy's dependencies")
							}
						} catch (RuntimeException e) {
							LOG.error("Property "+prop.fullName+" contentType could not be validated", e)
						}
					}
				}
			}
		}
		_hierarchy
	}

	/** The Hierarchy; the HierarchyBuilder is closed after creating it. */
	final def hierarchy() {
		_hierarchy
	}

	/**
	 * Searches for a Type by Class.
	 * Does not delegate to dependencies.
	 */
	final def <E> Type<E> findTypeDirect(Class<E> clazz) {
		for (pkg : allPackages) {
			for (type : pkg.types) {
				if (type.type == clazz) {
					return type as Type<E>
				}
			}
		}
		null
	}
}
