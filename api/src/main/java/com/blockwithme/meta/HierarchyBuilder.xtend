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
import com.blockwithme.meta.converter.IntConverter
import com.blockwithme.meta.converter.BooleanConverter
import com.blockwithme.meta.converter.ByteConverter
import com.blockwithme.meta.converter.CharConverter
import com.blockwithme.meta.converter.ShortConverter
import com.blockwithme.meta.converter.FloatConverter
import com.blockwithme.meta.converter.DoubleConverter
import com.blockwithme.meta.converter.LongConverter

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

	/** Constructor. Takes the hierarchy name as parameter. */
	new(String theName) {
		name = requireNonEmpty(theName, "theName")
	}

	/** Constructor. Takes a type specifying the hierarchy name as parameter. */
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
		LOG.info("Type "+theType.fullName+" registered in Hierarchy "+this.name)
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
		int theBits, boolean theMeta, Class<PROPERTY_TYPE> dataType) {
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
		LOG.info("Property "+prop.fullName+" registered in Hierarchy "+this.name)
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
		int theBits, boolean theMeta, Class<PROPERTY_TYPE> dataType) {
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
		int theBits, Class<PROPERTY_TYPE> dataType) {
		val _meta = MetaBase.isAssignableFrom(theOwner)
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

	/** We're done! */
	def close() {
		synch(this) [
			closed = true
		]
	}

	/* Helper method, to completely hide the implementation of interfaces */
	def <JAVA_TYPE> Functions.Function0<JAVA_TYPE> createProvider(Class<JAVA_TYPE> interfaze) {
		val pkg = requireNonNull(interfaze, "interfaze").package.name
		val name = interfaze.simpleName
		val providerName = pkg+".impl."+name+"ImplProvider"
		val impl = Class.forName(providerName)
		impl.newInstance as Functions.Function0<JAVA_TYPE>
	}

	// Now comes the factory methods
	// TODO These should delegate to a *user-configurable* Factory

	/** Creates a Boolean Property */
	def <OWNER_TYPE> TrueBooleanProperty<OWNER_TYPE> newBooleanProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		BooleanFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectBoolean<OWNER_TYPE,OWNER_TYPE> theSetter) {
		new TrueBooleanProperty<OWNER_TYPE>(this, theOwner, theSimpleName, theGetter, theSetter)
	}

	/** Creates a Boolean Property */
	def <OWNER_TYPE> TrueBooleanProperty<OWNER_TYPE> newBooleanProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		BooleanPropertyAccessor<OWNER_TYPE> theAccessor) {
		new TrueBooleanProperty<OWNER_TYPE>(this, theOwner, theSimpleName, theAccessor, theAccessor)
	}

	/** Creates a Boolean Property */
	def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends BooleanConverter<OWNER_TYPE, PROPERTY_TYPE>>
		BooleanProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> newBooleanProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, Class<PROPERTY_TYPE> dataType,
		BooleanPropertyAccessor<OWNER_TYPE> theAccessor) {
		new BooleanProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER>(
			this, theOwner, theSimpleName, theConverter, dataType,
			theAccessor, theAccessor)
	}

	/** Creates a Boolean Property */
	def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends BooleanConverter<OWNER_TYPE, PROPERTY_TYPE>>
		BooleanProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> newBooleanProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, Class<PROPERTY_TYPE> dataType,
		BooleanFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectBoolean<OWNER_TYPE,OWNER_TYPE> theSetter) {
		new BooleanProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER>(
			this, theOwner, theSimpleName, theConverter, dataType,
			theGetter, theSetter)
	}

	/** Creates a Byte Property */
	def <OWNER_TYPE> TrueByteProperty<OWNER_TYPE> newByteProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		ByteFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectByte<OWNER_TYPE,OWNER_TYPE> theSetter) {
		new TrueByteProperty<OWNER_TYPE>(this, theOwner, theSimpleName, theGetter, theSetter)
	}

	/** Creates a Byte Property */
	def <OWNER_TYPE> TrueByteProperty<OWNER_TYPE> newByteProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		BytePropertyAccessor<OWNER_TYPE> theAccessor) {
		new TrueByteProperty<OWNER_TYPE>(this, theOwner, theSimpleName, theAccessor, theAccessor)
	}

	/** Creates a Byte Property */
	def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends ByteConverter<OWNER_TYPE, PROPERTY_TYPE>>
		ByteProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> newByteProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, int theBits, Class<PROPERTY_TYPE> dataType,
		BytePropertyAccessor<OWNER_TYPE> theAccessor) {
		new ByteProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER>(
			this, theOwner, theSimpleName, theConverter, theBits, dataType,
			theAccessor, theAccessor)
	}

	/** Creates a Byte Property */
	def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends ByteConverter<OWNER_TYPE, PROPERTY_TYPE>>
		ByteProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> newByteProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, int theBits, Class<PROPERTY_TYPE> dataType,
		ByteFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectByte<OWNER_TYPE,OWNER_TYPE> theSetter) {
		new ByteProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER>(
			this, theOwner, theSimpleName, theConverter, theBits, dataType,
			theGetter, theSetter)
	}

	/** Creates a Character Property */
	def <OWNER_TYPE> TrueCharacterProperty<OWNER_TYPE> newCharacterProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CharFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectChar<OWNER_TYPE,OWNER_TYPE> theSetter) {
		new TrueCharacterProperty<OWNER_TYPE>(this, theOwner, theSimpleName, theGetter, theSetter)
	}

	/** Creates a Character Property */
	def <OWNER_TYPE> TrueCharacterProperty<OWNER_TYPE> newCharacterProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CharPropertyAccessor<OWNER_TYPE> theAccessor) {
		new TrueCharacterProperty<OWNER_TYPE>(this, theOwner, theSimpleName, theAccessor, theAccessor)
	}

	/** Creates a Character Property */
	def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends CharConverter<OWNER_TYPE, PROPERTY_TYPE>>
		CharacterProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> newCharacterProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, int theBits, Class<PROPERTY_TYPE> dataType,
		CharPropertyAccessor<OWNER_TYPE> theAccessor) {
		new CharacterProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER>(
			this, theOwner, theSimpleName, theConverter, theBits, dataType,
			theAccessor, theAccessor)
	}

	/** Creates a Character Property */
	def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends CharConverter<OWNER_TYPE, PROPERTY_TYPE>>
		CharacterProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> newCharacterProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, int theBits, Class<PROPERTY_TYPE> dataType,
		CharFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectChar<OWNER_TYPE,OWNER_TYPE> theSetter) {
		new CharacterProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER>(
			this, theOwner, theSimpleName, theConverter, theBits, dataType,
			theGetter, theSetter)
	}

	/** Creates a Short Property */
	def <OWNER_TYPE> TrueShortProperty<OWNER_TYPE> newShortProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		ShortFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectShort<OWNER_TYPE,OWNER_TYPE> theSetter) {
		new TrueShortProperty<OWNER_TYPE>(this, theOwner, theSimpleName, theGetter, theSetter)
	}

	/** Creates a Short Property */
	def <OWNER_TYPE> TrueShortProperty<OWNER_TYPE> newShortProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		ShortPropertyAccessor<OWNER_TYPE> theAccessor) {
		new TrueShortProperty<OWNER_TYPE>(this, theOwner, theSimpleName, theAccessor, theAccessor)
	}

	/** Creates a Short Property */
	def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends ShortConverter<OWNER_TYPE, PROPERTY_TYPE>>
		ShortProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> newShortProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, int theBits, Class<PROPERTY_TYPE> dataType,
		ShortPropertyAccessor<OWNER_TYPE> theAccessor) {
		new ShortProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER>(
			this, theOwner, theSimpleName, theConverter, theBits, dataType,
			theAccessor, theAccessor)
	}

	/** Creates a Short Property */
	def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends ShortConverter<OWNER_TYPE, PROPERTY_TYPE>>
		ShortProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> newShortProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, int theBits, Class<PROPERTY_TYPE> dataType,
		ShortFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectShort<OWNER_TYPE,OWNER_TYPE> theSetter) {
		new ShortProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER>(
			this, theOwner, theSimpleName, theConverter, theBits, dataType,
			theGetter, theSetter)
	}

	/** Creates a Float Property */
	def <OWNER_TYPE> TrueFloatProperty<OWNER_TYPE> newFloatProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		FloatFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectFloat<OWNER_TYPE,OWNER_TYPE> theSetter) {
		new TrueFloatProperty<OWNER_TYPE>(this, theOwner, theSimpleName, theGetter, theSetter)
	}

	/** Creates a Float Property */
	def <OWNER_TYPE> TrueFloatProperty<OWNER_TYPE> newFloatProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		FloatPropertyAccessor<OWNER_TYPE> theAccessor) {
		new TrueFloatProperty<OWNER_TYPE>(this, theOwner, theSimpleName, theAccessor, theAccessor)
	}

	/** Creates a Float Property */
	def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends FloatConverter<OWNER_TYPE, PROPERTY_TYPE>>
		FloatProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> newFloatProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, Class<PROPERTY_TYPE> dataType,
		FloatPropertyAccessor<OWNER_TYPE> theAccessor) {
		new FloatProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER>(
			this, theOwner, theSimpleName, theConverter, dataType,
			theAccessor, theAccessor)
	}

	/** Creates a Float Property */
	def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends FloatConverter<OWNER_TYPE, PROPERTY_TYPE>>
		FloatProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> newFloatProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, Class<PROPERTY_TYPE> dataType,
		FloatFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectFloat<OWNER_TYPE,OWNER_TYPE> theSetter) {
		new FloatProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER>(
			this, theOwner, theSimpleName, theConverter, dataType,
			theGetter, theSetter)
	}

	/** Creates a Integer Property */
	def <OWNER_TYPE> TrueIntegerProperty<OWNER_TYPE> newIntegerProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		IntFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectInt<OWNER_TYPE,OWNER_TYPE> theSetter) {
		new TrueIntegerProperty<OWNER_TYPE>(this, theOwner, theSimpleName, theGetter, theSetter)
	}

	/** Creates a Integer Property */
	def <OWNER_TYPE> TrueIntegerProperty<OWNER_TYPE> newIntegerProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		IntPropertyAccessor<OWNER_TYPE> theAccessor) {
		new TrueIntegerProperty<OWNER_TYPE>(this, theOwner, theSimpleName, theAccessor, theAccessor)
	}

	/** Creates a Integer Property */
	def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends IntConverter<OWNER_TYPE, PROPERTY_TYPE>>
		IntegerProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> newIntegerProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, int theBits, Class<PROPERTY_TYPE> dataType,
		IntPropertyAccessor<OWNER_TYPE> theAccessor) {
		new IntegerProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER>(
			this, theOwner, theSimpleName, theConverter, theBits, dataType,
			theAccessor, theAccessor)
	}

	/** Creates a Integer Property */
	def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends IntConverter<OWNER_TYPE, PROPERTY_TYPE>>
		IntegerProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> newIntegerProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, int theBits, Class<PROPERTY_TYPE> dataType,
		IntFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectInt<OWNER_TYPE,OWNER_TYPE> theSetter) {
		new IntegerProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER>(
			this, theOwner, theSimpleName, theConverter, theBits, dataType,
			theGetter, theSetter)
	}

	/** Creates a Double Property */
	def <OWNER_TYPE> TrueDoubleProperty<OWNER_TYPE> newDoubleProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		DoubleFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectDouble<OWNER_TYPE,OWNER_TYPE> theSetter) {
		new TrueDoubleProperty<OWNER_TYPE>(this, theOwner, theSimpleName, theGetter, theSetter)
	}

	/** Creates a Double Property */
	def <OWNER_TYPE> TrueDoubleProperty<OWNER_TYPE> newDoubleProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		DoublePropertyAccessor<OWNER_TYPE> theAccessor) {
		new TrueDoubleProperty<OWNER_TYPE>(this, theOwner, theSimpleName, theAccessor, theAccessor)
	}

	/** Creates a Double Property */
	def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends DoubleConverter<OWNER_TYPE, PROPERTY_TYPE>>
		DoubleProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> newDoubleProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, Class<PROPERTY_TYPE> dataType,
		DoublePropertyAccessor<OWNER_TYPE> theAccessor) {
		new DoubleProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER>(
			this, theOwner, theSimpleName, theConverter, dataType,
			theAccessor, theAccessor)
	}

	/** Creates a Double Property */
	def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends DoubleConverter<OWNER_TYPE, PROPERTY_TYPE>>
		DoubleProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> newDoubleProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, Class<PROPERTY_TYPE> dataType,
		DoubleFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectDouble<OWNER_TYPE,OWNER_TYPE> theSetter) {
		new DoubleProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER>(
			this, theOwner, theSimpleName, theConverter, dataType,
			theGetter, theSetter)
	}

	/** Creates a Long Property */
	def <OWNER_TYPE> TrueLongProperty<OWNER_TYPE> newLongProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		LongFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectLong<OWNER_TYPE,OWNER_TYPE> theSetter) {
		new TrueLongProperty<OWNER_TYPE>(this, theOwner, theSimpleName, theGetter, theSetter)
	}

	/** Creates a Long Property */
	def <OWNER_TYPE> TrueLongProperty<OWNER_TYPE> newLongProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		LongPropertyAccessor<OWNER_TYPE> theAccessor) {
		new TrueLongProperty<OWNER_TYPE>(this, theOwner, theSimpleName, theAccessor, theAccessor)
	}

	/** Creates a Long Property */
	def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends LongConverter<OWNER_TYPE, PROPERTY_TYPE>>
		LongProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> newLongProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, int theBits, Class<PROPERTY_TYPE> dataType,
		LongPropertyAccessor<OWNER_TYPE> theAccessor) {
		new LongProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER>(
			this, theOwner, theSimpleName, theConverter, theBits, dataType,
			theAccessor, theAccessor)
	}

	/** Creates a Long Property */
	def <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends LongConverter<OWNER_TYPE, PROPERTY_TYPE>>
		LongProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> newLongProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, int theBits, Class<PROPERTY_TYPE> dataType,
		LongFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectLong<OWNER_TYPE,OWNER_TYPE> theSetter) {
		new LongProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER>(
			this, theOwner, theSimpleName, theConverter, theBits, dataType,
			theGetter, theSetter)
	}

	/** Creates a Object Property */
	def <OWNER_TYPE, PROPERTY_TYPE> ObjectProperty<OWNER_TYPE, PROPERTY_TYPE> newObjectProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		Class<PROPERTY_TYPE> theContentType, boolean theShared, boolean theActualInstance,
		boolean theExactType, ObjectFuncObject<PROPERTY_TYPE,OWNER_TYPE> theGetter,
		ObjectFuncObjectObject<OWNER_TYPE,OWNER_TYPE,PROPERTY_TYPE> theSetter) {
		new ObjectProperty<OWNER_TYPE, PROPERTY_TYPE>(this, theOwner, theSimpleName,
			theContentType, theShared, theActualInstance, theExactType, theGetter, theSetter
		)
	}

	/** Creates a Object Property */
	def <OWNER_TYPE, PROPERTY_TYPE> ObjectProperty<OWNER_TYPE, PROPERTY_TYPE> newObjectProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		Class<PROPERTY_TYPE> theContentType, boolean theShared, boolean theActualInstance,
		boolean theExactType, ObjectPropertyAccessor<OWNER_TYPE,PROPERTY_TYPE> theAccessor) {
		new ObjectProperty<OWNER_TYPE, PROPERTY_TYPE>(this, theOwner, theSimpleName,
			theContentType, theShared, theActualInstance, theExactType, theAccessor, theAccessor)
	}

	/** Creates a new Type */
	def <JAVA_TYPE> Type<JAVA_TYPE> newType(Class<JAVA_TYPE> theType,
		Functions.Function0<JAVA_TYPE> theConstructor, Kind theKind,
		Property<JAVA_TYPE,?> ... theProperties) {
		new Type(this, theType, theConstructor, theKind, theProperties)
	}

	/** Creates a new Type */
	def <JAVA_TYPE> Type<JAVA_TYPE> newType(Class<JAVA_TYPE> theType,
		Functions.Function0<JAVA_TYPE> theConstructor, Kind theKind, Type<?>[] theParents,
		Property<JAVA_TYPE,?> ... theProperties) {
		new Type(this, theType, theConstructor, theKind, theParents, theProperties)
	}

	/** Creates a new TypePackage */
	def TypePackage newTypePackage(Type<?> ... theTypes) {
		new TypePackage(this, theTypes)
	}

	/** Creates a new Hierarchy */
	def Hierarchy newHierarchy(TypePackage[] packages, Hierarchy ... theDependencies) {
		val result = new Hierarchy(this, registerPackage(packages), theDependencies)
		close()
		result
	}

	/** Creates a new Hierarchy */
	def Hierarchy newHierarchy(Hierarchy ... theDependencies) {
		newHierarchy(newArrayOfSize(0), theDependencies)
	}

	/** Creates a new Hierarchy */
	def Hierarchy newHierarchy(TypePackage... packages) {
		newHierarchy(packages, newArrayOfSize(0))
	}

	/** Creates a new Hierarchy */
	def Hierarchy newHierarchy(HierarchyBuilder builder) {
		newHierarchy(newArrayOfSize(0), newArrayOfSize(0))
	}
}
