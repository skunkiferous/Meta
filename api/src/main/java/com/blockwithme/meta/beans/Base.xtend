/*
 * Copyright (C) 2014 Sebastien Diot.
 *
 * Licensed under the Apache License, Version 2.0 (the "License")
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
package com.blockwithme.meta.beans

import com.blockwithme.meta.BooleanProperty
import com.blockwithme.meta.ByteProperty
import com.blockwithme.meta.CharacterProperty
import com.blockwithme.meta.ContentOwner
import com.blockwithme.meta.DoubleProperty
import com.blockwithme.meta.FloatProperty
import com.blockwithme.meta.HierarchyBuilderFactory
import com.blockwithme.meta.IntegerProperty
import com.blockwithme.meta.JavaMeta
import com.blockwithme.meta.Kind
import com.blockwithme.meta.LongProperty
import com.blockwithme.meta.ObjectProperty
import com.blockwithme.meta.Property
import com.blockwithme.meta.ShortProperty
import com.blockwithme.meta.Type
import java.util.Collection
import java.util.List
import java.util.Set
import java.util.Map
import java.util.logging.Logger
import java.util.Objects
import com.blockwithme.meta.PropertyVisitor
import com.blockwithme.meta.beans.impl.AbstractBeanVisitor

/** Base for all data/bean objects */
interface Bean {
	/** Returns the true if the instance is immutable */
    def boolean isImmutable()

    /** Returns a full mutable copy */
    def Bean copy()

    /** Returns an immutable copy */
    def Bean snapshot()

    /** Returns a lightweight mutable copy */
    def Bean wrapper()

    /** Returns the Logger for this Bean */
    def Logger log()
}

/**
 * "Internal" base for all data/bean objects.
 *
 * The "selected" state is usually used to keep track of the "dirty" state.
 */
interface _Bean extends Bean, BeanVisitable {
	/** Returns the Type of the instance */
    def Type<?> getMetaType()

	/** Returns the current value of the change counter */
	def int getChangeCounter()

	/** Sets the current value of the change counter */
	def void setChangeCounter(int newValue)

	/** Returns the delegate, if any */
    def _Bean getDelegate()

	/** Sets the delegate (can be null) */
    def void setDelegate(_Bean delegate, boolean clearSelection,
            boolean alsoClearChangeCounter, boolean clearRecursively)

	/** Sets the delegate (can be null); does not clear selection */
    def void setDelegate(_Bean delegate)

	/** Returns the interceptor (cannot be null) */
    def Interceptor getInterceptor()

	/** Sets the interceptor (cannot be null) */
    def void setInterceptor(Interceptor newInterceptor)

    /** Returns the "parent" Bean, if any. */
    def _Bean getParentBean()

    /** Returns the key/index in the "parent", if any. */
    def Object getParentKey()

    /** Sets the "parent" Bean and optional key/index, if any. */
    def void setParentBeanAndKey(_Bean parent, Object key)

	/** Returns true, if some property was selected */
    def boolean isSelected()

	/** Returns true, if some property was selected, either in self, or in children */
    def boolean isSelectedRecursive()

	/** Returns true, if the specified property was selected */
    def boolean isSelected(Property<?,?> prop)

    /** Returns true if the specified property at the given index was selected */
    def boolean isSelected(int index)

	/** Marks the specified property as selected */
    def void setSelected(Property<?,?> prop)

	/** Marks the specified property at the given index as selected */
    def void setSelected(int index)

	/**
	 * Marks the specified property at the given index as selected,
	 * as well as all the properties that follow.
	 */
    def void setSelectedFrom(int index)

	/** Adds all the selected properties to "selected" */
    def void getSelectedProperty(Collection<Property<?,?>> selected)

	/** Cleans all selected flags */
    def void clearSelection(boolean alsoChangeCounter, boolean recursively)

	/** Sets all selected flags to true, including the children */
    def void setSelectionRecursive()

    /** Sets the immutable flag to true. */
    def void makeImmutable()

    /** Computes the JSON representation */
    def void toJSON(Appendable appendable)

    /** Returns the "root" Bean, if any. */
    def _Bean getRootBean()

    /** Returns true, if this Bean has the same (non-null) root as the Bean passed as parameter */
    def boolean hasSameRoot(_Bean other)

    /** Returns the index to use for this property. */
    def int indexOfProperty(Property<?, ?> prop)

    /**
     * Resolves a BeanPath to a value (including null, if the value, or any link, is null),
     * or fails, if failOnIncompatbileProperty is true, and an "incompatible" Property
     * is encountered along the way.
     *
     * TODO Test! (Including collections and maps)
     */
    def Object resolvePath(BeanPath<?,?> path, boolean failOnIncompatbileProperty)

    // TODO Create standard Immutable-Static-Reference @Data object, with working serialization.
}


/**
 * The Bean visitor
 */
interface BeanVisitor extends PropertyVisitor {
  /** Visits a _Bean */
  def void visit(_Bean bean)

  /**
   * Defines the start of the visit of a non-Bean.
   *
   * If it returns true, then the non-Bean should also write it's properties.
   * In all case, it should then call endVisitNonBean()
   */
  def boolean startVisitNonBean(Object nonBean)

  /**
   * Defines the end of the visit of a non-Bean.
   */
  def void endVisitNonBean(Object nonBean)

	/** Visit non-Bean boolean properties with their value */
	def void visitNonBeanProperty(String propName, boolean value)

	/** Visit non-Bean byte properties with their value */
	def void visitNonBeanProperty(String propName, byte value)

	/** Visit non-Bean char properties with their value */
	def void visitNonBeanProperty(String propName, char value)

	/** Visit non-Bean short properties with their value */
	def void visitNonBeanProperty(String propName, short value)

	/** Visit non-Bean int properties with their value */
	def void visitNonBeanProperty(String propName, int value)

	/** Visit non-Bean long properties with their value */
	def void visitNonBeanProperty(String propName, long value)

	/** Visit non-Bean float properties with their value */
	def void visitNonBeanProperty(String propName, float value)

	/** Visit non-Bean double properties with their value */
	def void visitNonBeanProperty(String propName, double value)

	/** Visit non-Bean Object properties with their value */
	def void visitNonBeanProperty(String propName, Object obj)
}


/** Interface for Objects that support the BeanVisitor explicitly. */
interface BeanVisitable {
  /** Accepts the visitor */
	def void accept(BeanVisitor visitor)
}


/**
 * Represents a "path", within a tree of Beans.
 *
 * Remember that paths can also "go up" by using the "parent" Property.
 */
@Data
class BeanPath<OWNER_TYPE, PROPERTY_TYPE> {
	/** A Property, that points to the next BeanPath owner, if any, otherwise to the desired value. */
	com.blockwithme.meta.Property<OWNER_TYPE, PROPERTY_TYPE> property
	/** The optional key/index, within the Property object, pointing to next, if Property is a Map/Collection */
	Object key
	/** The next link in the path, unless we are at the value, in which case it is null. */
	BeanPath<?,?> next

  new(Property<OWNER_TYPE, PROPERTY_TYPE> property, Object key, BeanPath<?, ?> next) {
    this._property = Objects.requireNonNull(property, "property")
    if (key instanceof Bean) {
    	throw new IllegalArgumentException(
    		"Beans are not supported as keys (keys must be immutable). Got: "+key.class)
    }
    this._key = key
    this._next = next
  }

  new(Property<OWNER_TYPE, PROPERTY_TYPE> property, BeanPath<?, ?> next) {
    this(property, null, next)
  }

  new(Property<OWNER_TYPE, PROPERTY_TYPE> property) {
    this(property, null, null)
  }

  override String toString() {
    return "BeanPath("+property.fullName+","+key+","+next+")";
  }

  /** Builds a full Bean path, from a list of Properties */
  def static BeanPath[] from(Property ... props) {
  	val len = props.length
  	val result = <BeanPath>newArrayOfSize(len)
  	var i = len-1
  	var BeanPath last = null
  	while (i > 0) {
  		val p = props.get(i) as Property
  		var next = new BeanPath(p, last)
  		result.set(i,next)
  		next = last
  		i--
  	}
  	result
  }
}


/**
 * The "context" within which an Entity exists.
 * It could be a JPA table, or anything that contains entities.
 */
interface EntityContext {
	/**
	 * Returns the unique ID (within this context) of the entity.
	 * Null maps to null.
	 */
	def String getIDAsString(Entity entity)

	/**
	 * Finds/loads/creates/.. and entity, based on it's ID.
	 * TODO This must be *async*
	 */
	def Entity getEntityFromID(String idAsString)
}

/**
 * Entities are beans that have a "independent lifecycle".
 * If an Entity is the root of a Bean tree, it "owns" that tree.
 * Otherwise, it is just "referenced" by the tree.
 *
 * TODO An Entity should support a standard request, where it receives
 * a Provider for a View (a new interface that must extend Bean, and define
 * an initView(? extends Entity) method), create the View, call it's initView()
 * with this as parameter, and then return the View as a reply. This should
 * even work across JVMs, if the Provider can be resolved, and the serialization
 * of Beans is automatic.
 *
 * TODO If we implement transactional Beans (the control over the transaction must
 * run over the Entity), then we must also be able to change things like the "parent"
 * transactionally, and this must still work, with multiple changes to the same field
 * within the same transaction. And object/tree-global validation must come right
 * before the commit.
 *
 * TODO If an error comes *during* the commit, as opposed to before the commit,
 * which is when the validation runs, then there is no saying what the state of
 * the objects are, and so I have to reload the whole tree.
 *
 * TODO With transactions, property change events can only ever be fired, if at all,
 * after a successful commit, because otherwise, nothing changed and so there is
 * no change to fire. And this means we could bundle all the changes in one single
 * fire event (request). But to fire, one has to clearly identify the source of
 * the event, and that might not be easy, in particular across the network.
 */
interface Entity extends Bean {
	// NOP
}

/**
 * "Internal" Entity interface.
 */
interface _Entity extends Entity, _Bean {
	/** Return the context owning this entity. */
	def EntityContext getEntityContext()

	/** Sets the context owning this entity. */
	def void setEntityContext(EntityContext entityContext)

	/** Returns the creation time in milliseconds */
	def long getCreationTime()

	/** Sets the creation time in milliseconds */
	def void setCreationTime(long creationTime)

	/** Returns the last modification time in milliseconds */
	def long getLastModificationTime()

	/** Sets the last modification time in milliseconds */
	def void setLastModificationTime(long lastModificationTime)
}

/** Interceptor allows "delegation", "validation", ... */
interface Interceptor {
	/** Intercept the read access to a boolean property */
    def boolean getBooleanProperty(_Bean instance, BooleanProperty<?,?,?> prop, boolean value)

	/** Intercept the write access to a boolean property */
    def boolean setBooleanProperty(_Bean instance, BooleanProperty<?,?,?> prop, boolean oldValue,
            boolean newValue)

	/** Intercept the read access to a byte property */
    def byte getByteProperty(_Bean instance, ByteProperty<?,?,?> prop, byte value)

	/** Intercept the write access to a boolean property */
    def byte setByteProperty(_Bean instance, ByteProperty<?,?,?> prop, byte oldValue,
            byte newValue)

	/** Intercept the read access to a char property */
    def char getCharacterProperty(_Bean instance, CharacterProperty<?,?,?> prop, char value)

	/** Intercept the write access to a char property */
    def char setCharacterProperty(_Bean instance, CharacterProperty<?,?,?> prop, char oldValue,
            char newValue)

	/** Intercept the read access to a short property */
    def short getShortProperty(_Bean instance, ShortProperty<?,?,?> prop, short value)

	/** Intercept the write access to a short property */
    def short setShortProperty(_Bean instance, ShortProperty<?,?,?> prop, short oldValue,
            short newValue)

	/** Intercept the read access to a int property */
    def int getIntegerProperty(_Bean instance, IntegerProperty<?,?,?> prop, int value)

	/** Intercept the write access to a int property */
    def int setIntegerProperty(_Bean instance, IntegerProperty<?,?,?> prop, int oldValue,
            int newValue)

	/** Intercept the read access to a float property */
    def float getFloatProperty(_Bean instance, FloatProperty<?,?,?> prop, float value)

	/** Intercept the write access to a float property */
    def float setFloatProperty(_Bean instance, FloatProperty<?,?,?> prop, float oldValue,
            float newValue)

	/** Intercept the read access to a double property */
    def double getDoubleProperty(_Bean instance, DoubleProperty<?,?,?> prop, double value)

	/** Intercept the write access to a double property */
    def double setDoubleProperty(_Bean instance, DoubleProperty<?,?,?> prop, double oldValue,
            double newValue)

	/** Intercept the read access to a long property */
    def long getLongProperty(_Bean instance, LongProperty<?,?,?> prop, long value)

	/** Intercept the write access to a long property */
    def long setLongProperty(_Bean instance, LongProperty<?,?,?> prop, long oldValue,
            long newValue)

	/** Intercept the read access to a Object property */
    def <E> E getObjectProperty(_Bean instance, ObjectProperty<?,E,?,?> prop, E value)

	/** Intercept the write access to a Object property */
    def <E> E setObjectProperty(_Bean instance, ObjectProperty<?,E,?,?> prop, E oldValue,
            E newValue)
}

/** Interceptor for collections of objects */
interface ObjectCollectionInterceptor<E> extends Interceptor {
	/** Intercept the read access to a Object element in a collection */
    def E getObjectAtIndex(_CollectionBean<E> instance, int index, E value)

	/** Intercept the write access to a Object element in a collection */
    def E setObjectAtIndex(_CollectionBean<E> instance, int index, E oldValue,
            E newValue)

	/** Intercept the insert access to a Object element in a collection */
    def E addObjectAtIndex(_CollectionBean<E> instance, int index, E newValue, boolean followingElementsChanged)

	/** Intercept the remove access to a Object element in a collection */
    def void removeObjectAtIndex(_CollectionBean<E> instance, int index, E value, boolean followingElementsChanged)

	/** Intercept the clear to a collection */
    def void clear(_CollectionBean<E> instance)

}

/** Interceptor for Map of objects */
interface ObjectObjectMapInterceptor<K,V> extends Interceptor {
	/** Intercept the read access to a Object key in a Map */
    def K getKeyAtIndex(_MapBean<K, V> instance, int index, K key)

	/** Intercept the read access to a Object value in a Map */
    def V getValueAtIndex(_MapBean<K, V> instance, int index, V value)

	/** Intercept the write access to a Object key in a Map */
    def K setKeyAtIndex(_MapBean<K, V> instance, int index, K oldKey,
            K newKey)

	/** Intercept the write access to a Object value in a Map */
    def V setValueAtIndex(_MapBean<K, V> instance, K key, int index, V oldValue,
            V newValue)

	/** Intercept the clear to a Map */
    def void clear(_MapBean<K, V> instance)

}

/** A Bean that represents a Collection (either List or Set) */
interface CollectionBean<E> extends Collection<E>, ContentOwner<E>, Bean {
    /** Returns the CollectionBeanConfig */
    def CollectionBeanConfig getConfig()
    /** Returns the value Type (E) */
    def Type<E> getValueType()
}

/** A Bean that represents a List */
interface ListBean<E> extends List<E>, CollectionBean<E> {
}

/** A Bean that represents a Set */
interface SetBean<E> extends Set<E>, CollectionBean<E> {
}

/** A Bean that represents a Collection (either List or Set) */
interface _CollectionBean<E> extends CollectionBean<E>, _Bean {
	/** Returns the delegate, if any */
    override _CollectionBean<E> getDelegate()
}

/** A Bean that represents a List */
interface _ListBean<E> extends ListBean<E>, _CollectionBean<E> {
	/** Returns the delegate, if any */
    override _ListBean<E> getDelegate()
}

/** A Bean that represents a Set */
interface _SetBean<E> extends SetBean<E>, _CollectionBean<E> {
	/** Returns the delegate, if any */
    override _SetBean<E> getDelegate()
}

/** A Bean that represents a Map (always an HashMap) */
interface MapBean<K,V> extends Map<K,V>, ContentOwner<Map.Entry<K,V>>, Bean {
    /** Returns the key Type (K) */
    def Type<K> getKeyType()
    /** Returns the value Type (V) */
    def Type<V> getValueType()
}

/** A Bean that represents a Map (always an HashMap) */
interface _MapBean<K,V> extends MapBean<K,V>, _Bean {
	/** Returns the delegate, if any */
    override _MapBean<K,V> getDelegate()
}

/**
 * The "Meta" constant-holding interface for the meta-types themselves.
 *
 * The call to JavaMeta.HIERARCHY.findType() in META_BASE forces the Java
 * Hierarchy to be initialized before the Meta Hierarchy.
 */
 @SuppressWarnings("rawtypes")
interface Meta {
	/** The Hierarchy of Meta Types */
	val BUILDER = HierarchyBuilderFactory.getHierarchyBuilder(Bean.name)

	/** The Bean Type */
	val BEAN = BUILDER.newType(Bean, null, Kind.Trait)

	/** The change counter Bean property */
    val _BEAN__CHANGE_COUNTER = BUILDER.newIntegerProperty(
    	_Bean, "changeCounter", [changeCounter], [obj,value|obj.changeCounter = value;obj], false)

	/** The parent virtual Bean property */
    val _BEAN__PARENT_BEAN = BUILDER.newObjectProperty(
    	_Bean, "parentBean", _Bean, true, true, false, [parentBean], null, true)

	/** The parent "key" virtual Bean property */
    val _BEAN__PARENT_KEY = BUILDER.newObjectProperty(
    	_Bean, "parentKey", Object, true, true, false, [parentKey], null, true)

	/** The root virtual Bean property */
    val _BEAN__ROOT_BEAN = BUILDER.newObjectProperty(
    	_Bean, "rootBean", _Bean, true, true, false, [rootBean], null, true)

	/** The _Bean Type */
	val _BEAN = BUILDER.newType(_Bean, null, Kind.Trait, #[BEAN],
		com.blockwithme.meta.beans.Meta._BEAN__CHANGE_COUNTER,
		com.blockwithme.meta.beans.Meta._BEAN__PARENT_BEAN,
		com.blockwithme.meta.beans.Meta._BEAN__PARENT_KEY,
		com.blockwithme.meta.beans.Meta._BEAN__ROOT_BEAN)

	/** The Entity Type */
	val ENTITY = BUILDER.newType(Entity, null, Kind.Trait, #[BEAN])

	/** The _Entity Type */
	val _ENTITY = BUILDER.newType(_Entity, null, Kind.Trait, #[ENTITY, _BEAN])

	/** The CollectionBeanConfig Type; we pretend it has no property. */
	val COLLECTION_BEAN_CONFIG = BUILDER.newType(CollectionBeanConfig, null, Kind.Data)

	/** The configuration property of the collection beans */
    val COLLECTION_BEAN__CONFIG = BUILDER.newObjectProperty(
    	CollectionBean, "config", CollectionBeanConfig, true, true, true, [config], null, false)

	/** The value-type property of the collection beans */
    val COLLECTION_BEAN__VALUE_TYPE = BUILDER.newObjectProperty(
    	CollectionBean, "valueType", Type, true, true, true, [valueType], null, false)

	/** The CollectionBean Type */
	val COLLECTION_BEAN = BUILDER.newType(CollectionBean, null, Kind.Trait,
		#[BEAN, JavaMeta.LIST, JavaMeta.SET], <Property>newArrayList(COLLECTION_BEAN__CONFIG),
		COLLECTION_BEAN__VALUE_TYPE as ObjectProperty)

	/** The ListBean Type */
	val LIST_BEAN = BUILDER.newType(ListBean, null, Kind.Trait,
		#[COLLECTION_BEAN, JavaMeta.LIST], Property.NO_PROPERTIES,
		COLLECTION_BEAN__VALUE_TYPE as ObjectProperty)

	/** The SetBean Type */
	val SET_BEAN = BUILDER.newType(SetBean, null, Kind.Trait,
		#[COLLECTION_BEAN, JavaMeta.SET], Property.NO_PROPERTIES,
		COLLECTION_BEAN__VALUE_TYPE as ObjectProperty)

	/** The _CollectionBean Type */
	val _COLLECTION_BEAN = BUILDER.newType(_CollectionBean, null, Kind.Trait,
		#[COLLECTION_BEAN, _BEAN], Property.NO_PROPERTIES,
		COLLECTION_BEAN__VALUE_TYPE as ObjectProperty)

	/** The _ListBean Type */
	val _LIST_BEAN = BUILDER.newType(_ListBean, null, Kind.Trait,
		#[_COLLECTION_BEAN, LIST_BEAN], Property.NO_PROPERTIES,
		COLLECTION_BEAN__VALUE_TYPE as ObjectProperty)

	/** The _SetBean Type */
	val _SET_BEAN = BUILDER.newType(_SetBean, null, Kind.Trait,
		#[_COLLECTION_BEAN, SET_BEAN], Property.NO_PROPERTIES,
		COLLECTION_BEAN__VALUE_TYPE as ObjectProperty)

	/** The key-type property of the Map beans */
    val MAP_BEAN__KEY_TYPE = BUILDER.newObjectProperty(
    	MapBean, "keyType", Type, true, true, true, [keyType], null, false)

	/** The value-type property of the Map beans */
    val MAP_BEAN__VALUE_TYPE = BUILDER.newObjectProperty(
    	MapBean, "valueType", Type, true, true, true, [valueType], null, false)

	/** The MapBean Type */
	val MAP_BEAN = BUILDER.newType(MapBean, null, Kind.Trait,
		#[BEAN, JavaMeta.MAP], Property.NO_PROPERTIES, MAP_BEAN__KEY_TYPE as ObjectProperty,
		MAP_BEAN__VALUE_TYPE as ObjectProperty)

	/** The _MapBean Type */
	val _MAP_BEAN = BUILDER.newType(_MapBean, null, Kind.Trait,
		#[MAP_BEAN, _BEAN], Property.NO_PROPERTIES, MAP_BEAN__KEY_TYPE as ObjectProperty,
		MAP_BEAN__VALUE_TYPE as ObjectProperty)

	/** The Beans package */
	val COM_BLOCKWITHME_META_BEANS_PACKAGE = BUILDER.newTypePackage(
		BEAN, _BEAN, ENTITY, _ENTITY, COLLECTION_BEAN_CONFIG, COLLECTION_BEAN,
		_COLLECTION_BEAN, LIST_BEAN, SET_BEAN, _LIST_BEAN, _SET_BEAN, MAP_BEAN, _MAP_BEAN)

	/** The Hierarchy of Meta Types */
	val HIERARCHY = BUILDER.newHierarchy(COM_BLOCKWITHME_META_BEANS_PACKAGE)
}
