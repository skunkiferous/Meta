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
package com.blockwithme.meta.util

import java.util.logging.Logger
import com.blockwithme.meta.HierarchyBuilderFactory
import com.blockwithme.meta.Kind

/** Identifies an Object that can provide it's own Logger. */
interface Loggable {
    /** Returns the Logger for this Bean */
    def Logger log()
}

/**
 * The "Meta" constant-holding interface for the meta-types themselves.
 *
 * The call to JavaMeta.HIERARCHY.findType() in META_BASE forces the Java
 * Hierarchy to be initialized before the Meta Hierarchy.
 */
@SuppressWarnings("rawtypes")
public interface Meta {
    /** The Hierarchy of Meta Types */
    val BUILDER = HierarchyBuilderFactory.getHierarchyBuilder(Loggable.name)

	/** The log virtual Loggable property */
    val LOGGABLE__LOG = BUILDER.newObjectProperty(
    	Loggable, "log", Logger, true, true, false, false, [log], null, true)

	/** The Loggable Type */
	val LOGGABLE = BUILDER.newType(Loggable, null, Kind.Trait, null, null, Meta.LOGGABLE__LOG)

    /** The util package */
    val COM_BLOCKWITHME_META_UTIL_PACKAGE = BUILDER.newTypePackage(LOGGABLE)

    /** The Hierarchy of Meta Types */
    val HIERARCHY = BUILDER.newHierarchy(COM_BLOCKWITHME_META_UTIL_PACKAGE)
}
