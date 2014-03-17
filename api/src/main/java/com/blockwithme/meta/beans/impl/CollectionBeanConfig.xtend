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
package com.blockwithme.meta.beans.impl

import com.blockwithme.meta.Type
import java.util.concurrent.ConcurrentHashMap

/**
 * Contains the configuration data for a CollectionBean
 *
 * @author monster
 */
@Data
class CollectionBeanConfig {
	/** Fixed-size cache. */
	private static val ConcurrentHashMap<Integer,CollectionBeanConfig> FIXED_SIZE_CACHE = new ConcurrentHashMap

	/** A list, without null */
	public static val LIST = new CollectionBeanConfig(-1, false, false, false, false, false, false, true)

	/** A list, with null allowed */
	public static val NULL_LIST = new CollectionBeanConfig(-1, true, false, false, false, false, false, true)

	/** A sorted-set, without null */
	public static val SORTED_SET = new CollectionBeanConfig(-1, false, false, true, false, false, true, false)

	/** An ordered-set, without null */
	public static val ORDERED_SET = new CollectionBeanConfig(-1, false, false, false, true, false, true, false)

	/** An unordered-set, without null */
	public static val UNORDERED_SET = new CollectionBeanConfig(-1, false, false, false, false, true, true, false)

	/** The default type, for collections */
	public static val DEFAULT = UNORDERED_SET

	/** Either -1, or the "fixed-size" of the collection */
	int fixedSize
	/** Do we allow null values? (Must be true for fixed-size) */
	boolean nullAllowed
	/** Do we only accept the "exact type" of the component, as opposed to subclasses? */
	boolean onlyExactType
	/** Are we a sorted set? */
	boolean sortedSet
	/** Are we an ordered set? */
	boolean orderedSet
	/** Are we an unordered set? */
	boolean unorderedSet
	/** Are we any set? */
	boolean set
	/** Are we a list? */
	boolean list

	/** Validate self */
	def void validate(Type<?> metaType) {
		if ((fixedSize != -1) && !nullAllowed) {
			throw new IllegalStateException("(fixedSize != -1) && !nullAllowed")
		}
		if ((fixedSize != -1) && set) {
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
		if (sortedSet && !Comparable.isAssignableFrom(metaType.type)) {
			throw new IllegalStateException("sortedSet && !Comparable")
		}
	}

	/** Creates and caches a fixed-size CollectionBeanConfig */
	def static CollectionBeanConfig newFixedSizeList(int fixedSize, boolean onlyExactType) {
		if (fixedSize < 0) {
			throw new IllegalArgumentException("Fixed size cannot be negative: "+fixedSize)
		}
		val Integer key = fixedSize
		var result = FIXED_SIZE_CACHE.get(key)
		if (result === null) {
			result = new CollectionBeanConfig(fixedSize, true, onlyExactType, false, false, false, false, true)
			result = FIXED_SIZE_CACHE.putIfAbsent(key, result)
		}
		result
	}
}