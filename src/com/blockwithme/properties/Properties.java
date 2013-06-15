/*
 * Copyright (C) 2013 Sebastien Diot.
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
package com.blockwithme.properties;

/**
 * Represents an object that contains properties.
 *
 * Properties have a String key, and a value that can be one of the following:
 *
 * * A primitive value (wrapper)
 * * A String value
 * * A Class value
 * * An Enum value
 * * Another Properties
 * * A "generator"
 * * An array of one of the above
 *
 * A generator is a function-object, which "computes" the value to the property.
 * A generator constructor is expected to receive a String as parameter, to
 * allow for "generic configuration".
 *
 * A "link" is a kind of generator: a path that cause delegation to another
 * Properties object in the hierarchy.
 *
 * The links remove the need to repeat the same values in multiple places.
 * The methods recognize relative path, like in a file system, such that links
 * can just be implemented as a path.
 *
 * Keyes should be composed exclusively of the following characters:
 * [a-z|A-Z|0-9]
 *
 * The path separator is the Unix(tm) path separator: /
 * Relative path to parent is also as Unix(tm): ..
 *
 * When iterated, a Properties returns it's keyes.
 *
 * @author monster
 */
public interface Properties<TIME extends Comparable<TIME>> extends
        Iterable<String> {

    /** The path separator. */
    char SEPATATOR = '/';

    /** The "parent path". */
    String PARENT = "..";

    /** Returns the root of the Properties. */
    Root<TIME> root();

    /** Returns the parent of the Properties (null for root). */
    Properties<TIME> parent();

    /** Returns the key of this Properties, within it's parent ("" for root) */
    String localKey();

    /** Returns the global key of this Properties ("" for root) */
    String globalKey();

    /**
     * Returns the property value, if any. Null if absent.
     * Generators are executed, if executeGenerators is true.
     */
    <E> E findRaw(final String path, final boolean executeGenerators);

    /**
     * Returns the property value, if any, or the default value.
     * An exception is thrown, if the property exists, but has the wrong type.
     * Links are resolved.
     */
    <E> E find(final String path, final Class<E> type, final E defaultValue);

    /**
     * Returns the property value, if any, or null.
     * An exception is thrown, if the property exists, but has the wrong type.
     */
    <E> E find(final String path, final Class<E> type);

    /**
     * Returns the property value, if present, or throw an exception.
     * An exception is thrown, if the property exists, but has the wrong type.
     */
    <E> E get(final String path, final Class<E> type);

    /** Sets a property "immediatly". */
    void set(final String path, final Object value);

    /**
     * Sets a property at some point in time.
     * If when is null, or in the past, the changes are going to be performed
     * immediately. Otherwise, they will be buffered, until the time comes.
     */
    void set(final String path, final Object value, final TIME when);
}
