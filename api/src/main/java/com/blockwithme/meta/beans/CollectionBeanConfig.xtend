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
package com.blockwithme.meta.beans

import com.blockwithme.meta.Type
import com.blockwithme.meta.beans.impl._WitherImpl
import java.util.concurrent.ConcurrentHashMap

/**
 * CollectionBeanConfig is a configuration object for CollectionBeans.
 */
final class CollectionBeanConfig extends _WitherImpl {
	/** CollectionBeanConfig cache. */
	private static val ConcurrentHashMap<Integer,CollectionBeanConfig> CACHE = new ConcurrentHashMap

	/** An unordered-set, without null */
	public static val UNORDERED_SET = new CollectionBeanConfig(-1, "UNORDERED_SET", false, false, false, false, true, false, true, false)

	/** An ordered-set, without null */
	public static val ORDERED_SET = new CollectionBeanConfig(-2, "ORDERED_SET", false, false, false, true, false, false, true, false)

	/** An hash-set, without null */
	public static val HASH_SET = new CollectionBeanConfig(-3, "HASH_SET", false, false, false, false, false, true, true, false)

	/** A sorted-set, without null */
	public static val SORTED_SET = new CollectionBeanConfig(-4, "SORTED_SET", false, false, true, false, false, false, true, false)

	/** A list, without null */
	public static val LIST = new CollectionBeanConfig(-5, "LIST", false, false, false, false, false, false, false, true)

	/** A list, with null allowed */
	public static val NULL_LIST = new CollectionBeanConfig(-6, "NULL_LIST", true, false, false, false, false, false, false, true)

	/** A list, without null */
	public static val EXACT_LIST = new CollectionBeanConfig(-7, "EXACT_LIST", false, true, false, false, false, false, false, true)

	/** A list, with null allowed */
	public static val EXACT_NULL_LIST = new CollectionBeanConfig(-8, "EXACT_NULL_LIST", true, true, false, false, false, false, false, true)

	/** A sorted-set, without null */
	public static val EXACT_SORTED_SET = new CollectionBeanConfig(-9, "EXACT_SORTED_SET", false, true, true, false, false, false, true, false)

	/** An ordered-set, without null */
	public static val EXACT_ORDERED_SET = new CollectionBeanConfig(-10, "EXACT_ORDERED_SET", false, true, false, true, false, false, true, false)

	/** An unordered-set, without null */
	public static val EXACT_UNORDERED_SET = new CollectionBeanConfig(-11, "EXACT_UNORDERED_SET", false, true, false, false, true, false, true, false)

	/** An hash-set, without null */
	public static val EXACT_HASH_SET = new CollectionBeanConfig(-12, "EXACT_HASH_SET", false, true, false, false, false, true, true, false)

	/** The default type, for collections */
	public static val DEFAULT = UNORDERED_SET

	/** The internal ID */
	private val int id
	/** The String description */
	private transient val String name
	/** Do we allow null values? (Must be true for fixed-size) */
	private transient boolean nullAllowed
	/** Do we only accept the "exact type" of the component, as opposed to subclasses? */
	private transient boolean onlyExactType
	/** Are we a sorted set? */
	private transient boolean sortedSet
	/** Are we an ordered set? */
	private transient boolean orderedSet
	/** Are we an unordered set? */
	private transient boolean unorderedSet
	/** Are we an hash set? */
	private transient boolean hashSet
	/** Are we any set? */
	private transient boolean set
	/** Are we a list? */
	private transient boolean list

	/** Constructor */
	new(int theId, String theName, boolean theNullAllowed, boolean theOnlyExactType,
		boolean theSortedSet, boolean theOrderedSet, boolean theUnorderedSet,
		boolean theHashSet, boolean theSet, boolean theList) {
		super(Meta.COLLECTION_BEAN_CONFIG)
		id = theId
		name = theName
		nullAllowed = theNullAllowed
		onlyExactType = theOnlyExactType
		sortedSet = theSortedSet
		orderedSet = theOrderedSet
		unorderedSet = theUnorderedSet
		hashSet = theHashSet
		set = theSet
		list = theList
		if (id < 0) {
			CACHE.put(id, this)
		}
		toString = name
	}

	/** The ID */
	def int getId() {
		id
	}

	/** The String description */
	def String getName() {
		name
	}
	/** Either -1, or the "fixed-size" of the collection */
	def int getFixedSize() {
		if (id < 0) -1 else id/2
	}
	/** Do we allow null values? (Must be true for fixed-size) */
	def boolean isNullAllowed() {
		nullAllowed
	}
	/** Do we only accept the "exact type" of the component, as opposed to subclasses? */
	def boolean isOnlyExactType() {
		onlyExactType
	}
	/** Are we a sorted set? */
	def boolean isSortedSet() {
		sortedSet
	}
	/** Are we an ordered set? */
	def boolean isOrderedSet() {
		orderedSet
	}
	/** Are we an unordered set? */
	def boolean isUnorderedSet() {
		unorderedSet
	}
	/** Are we an hash set? */
	def boolean isHashSet() {
		hashSet
	}
	/** Are we any set? */
	def boolean isSet() {
		set
	}
	/** Are we a list? */
	def boolean isList() {
		list
	}

	/** Are we some kind of unordered set? */
	def boolean pseudoUnorderedSet() {
		unorderedSet || hashSet
	}

	/** Validate self */
	def void validate(Type<?> valueType) {
		if ((getFixedSize() != -1) && !nullAllowed) {
			throw new IllegalStateException("(fixedSize != -1) && !nullAllowed")
		}
		if ((getFixedSize() != -1) && set) {
			throw new IllegalStateException("(fixedSize != -1) && set")
		}
		if (nullAllowed && set) {
			throw new IllegalStateException("nullAllowed && set")
		}
		if (sortedSet && orderedSet) {
			throw new IllegalStateException("sortedSet && orderedSet")
		}
		if (sortedSet && unorderedSet) {
			throw new IllegalStateException("sortedSet && unorderedSet")
		}
		if (unorderedSet && orderedSet) {
			throw new IllegalStateException("unorderedSet && orderedSet")
		}
		if ((sortedSet || orderedSet || unorderedSet) && !set) {
			throw new IllegalStateException("(sortedSet || orderedSet || unorderedSet) && !set")
		}
		if (list && set) {
			throw new IllegalStateException("list && set")
		}
		if (!(list || set)) {
			throw new IllegalStateException("!(list || set)")
		}
		if (sortedSet && !Comparable.isAssignableFrom(valueType.type)) {
			throw new IllegalStateException("sortedSet && !Comparable")
		}
	}

	/** Creates and caches a fixed-size CollectionBeanConfig */
	def static CollectionBeanConfig newFixedSizeList(int fixedSize, boolean onlyExactType) {
		if (fixedSize < 0) {
			throw new IllegalArgumentException("Fixed size cannot be negative: "+fixedSize)
		}
		val id = if (onlyExactType) fixedSize*2 else (1 + fixedSize*2)
		val Integer key = id
		var result = CACHE.get(key)
		if (result === null) {
			val name = if (onlyExactType) {
				"FIXED("+fixedSize+",true)"
			} else {
				"FIXED("+fixedSize+",false)"
			}
			result = new CollectionBeanConfig(id, name, true, onlyExactType,
				false, false, false, false, false, true)
			val cached = CACHE.putIfAbsent(key, result)
			if (cached !== null) {
				result = cached
			}
		}
		result
	}

	/** Resolves a CollectionBeanConfig from it's ID */
	static def resolve(int id) {
		if (id < 0) {
			val result = CACHE.get(id)
			if (result === null) {
				throw new IllegalArgumentException("ID "+id)
			}
			return result
		}
		val onlyExactType = (id % 2 === 0)
		val fixedSize = id/2
		newFixedSizeList(fixedSize, onlyExactType)
	}

	/** Resolves a CollectionBeanConfig */
	static def resolve(CollectionBeanConfig config) {
		resolve(config.id)
	}
}