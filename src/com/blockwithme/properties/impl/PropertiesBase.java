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
package com.blockwithme.properties.impl;

import java.util.Objects;

import com.blockwithme.properties.Generator;
import com.blockwithme.properties.Properties;

/**
 * Base class for Properties.
 *
 * @author monster
 */
public abstract class PropertiesBase<TIME extends Comparable<TIME>> implements
        Properties<TIME> {

    /** The parent path. */
    protected static final String PARENT_PATH = PARENT + SEPATATOR;

    /** The local key. */
    private final String localKey;

    /** The global key. */
    private final String globalKey;

    /** The parent. */
    private final PropertiesBase<TIME> parent;

    /** Validates a local key. */
    public static String checkLocalKey(final String localKey,
            final String designation, final String fullPath) {
        if (localKey == null) {
            throw new IllegalArgumentException(designation + " is null");
        }
        if (localKey.isEmpty()) {
            throw new IllegalArgumentException(designation + " is empty");
        }
        for (final char c : localKey.toCharArray()) {
            final boolean lower = (c >= 'a') && (c <= 'z');
            final boolean upper = (c >= 'A') && (c <= 'Z');
            final boolean digit = (c >= '0') && (c <= '9');
            if (!(lower || upper || digit)) {
                throw new IllegalArgumentException(designation + "(" + fullPath
                        + ") contains illegal character: '" + c + "'");
            }
        }
        return localKey;
    }

    /**
     * Returns true if the key is a local key, and valid.
     * Returns false if not a local key.
     * Throws an exception if local key but not valid.
     */
    public static boolean isLocalKey(final String path,
            final String designation, final String fullPath) {
        final boolean local = (Objects.requireNonNull(path, designation)
                .indexOf(SEPATATOR) < 0) && !"..".equals(path);
        if (local) {
            checkLocalKey(path, designation, fullPath);
        }
        return local;
    }

    /** Constructs a PropertiesBase. */
    public PropertiesBase(final PropertiesBase<TIME> parent,
            final String localKey) {
        this.parent = parent;
        if (parent == null) {
            // Must be root!
            if ((localKey != null) && !"".equals(localKey)) {
                throw new IllegalArgumentException(
                        "Local key of root (parent == null) must be empty, but was: '"
                                + localKey + "'");
            }
            if (!(this instanceof ImplRoot<?>)) {
                throw new IllegalArgumentException(
                        "root (parent == null) must be an ImplRoot<?>");
            }
            globalKey = this.localKey = "";
        } else {
            this.localKey = checkLocalKey(localKey, "localKey", localKey);
            globalKey = parent.globalKey() + SEPATATOR + this.localKey;
            parent.setLocalProperty(this.localKey, this, null);
        }
    }

    /** toString */
    @Override
    public String toString() {
        return getClass().getSimpleName() + "(" + globalKey + ")";
    }

    /* (non-Javadoc)
     * @see com.blockwithme.properties.Properties#localKey()
     */
    @Override
    public final String localKey() {
        return localKey;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.properties.Properties#globalKey()
     */
    @Override
    public final String globalKey() {
        return globalKey;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.properties.Properties#parent()
     */
    @Override
    public final Properties<TIME> parent() {
        return parent;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.properties.Properties#root()
     */
    @Override
    public final ImplRoot<TIME> root() {
        Properties<TIME> previous = this;
        Properties<TIME> next = parent;
        while (next != null) {
            previous = next;
            next = next.parent();
        }
        return (ImplRoot<TIME>) previous;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.properties.Properties#find(java.lang.String, java.lang.Class, java.lang.Object)
     */
    @SuppressWarnings("unchecked")
    @Override
    public final <E> E find(final String path, final Class<E> type,
            final E defaultValue) {
        Objects.requireNonNull(type, "type");
        final Object obj = findRaw(path, type, true);
        if (obj == null) {
            return defaultValue;
        }
        if (!type.isInstance(obj)) {
            throw new IllegalStateException("Property '" + path + "' type is: "
                    + obj.getClass().getName() + " but expected type is: "
                    + type);
        }
        return (E) obj;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.properties.Properties#find(java.lang.String, java.lang.Class)
     */
    @Override
    public final <E> E find(final String path, final Class<E> type) {
        return find(path, type, null);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.properties.Properties#get(java.lang.String, java.lang.Class)
     */
    @Override
    public final <E> E get(final String path, final Class<E> type) {
        final E result = find(path, type, null);
        if (result == null) {
            throw new IllegalStateException("Property '" + path
                    + "' not found!");
        }
        return result;
    }

    /**
     * If value is not a generator, it does not check the type, and just returns it.
     * If it is a generator, then the generator is called.
     */
    private Object resolve(final Object value, final String localKey,
            final Class<?> type, final boolean executeGenerators) {
        if (executeGenerators && (value instanceof Generator)) {
            final Generator gen = (Generator) value;
            final Object result = gen.generate(this, localKey, type);
            if (result instanceof Generator) {
                throw new IllegalStateException("Generator "
                        + gen.getClass().getName() + " for property "
                        + localKey + " returned another generator: "
                        + result.getClass().getName());
            }
            return result;
        }
        return value;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.properties.Properties#findRaw(java.lang.String, boolean)
     */
    @SuppressWarnings("unchecked")
    private final Object findRaw(final String path, final Class<?> type,
            final boolean executeGenerators) {
        if (isLocalKey(path, "path", path)) {
            return resolve(findLocalRaw(path), path, type, executeGenerators);
        }
        PropertiesBase<TIME> prop = this;
        String relPath = path;
        if (path.charAt(0) == SEPATATOR) {
            // Absolute path ...
            prop = (PropertiesBase<TIME>) root();
            relPath = path.substring(1);
            if (relPath.isEmpty()) {
                return prop;
            }
        }
        while (true) {
            while (relPath.startsWith(PARENT_PATH)) {
                relPath = relPath.substring(PARENT_PATH.length());
                prop = (PropertiesBase<TIME>) prop.parent();
                if (relPath.isEmpty()) {
                    // OK, we wanted a "parent" ...
                    return prop;
                }
                if (prop == null) {
                    throw new IllegalArgumentException("invalid path: " + path);
                }
            }
            if (PARENT.equals(relPath)) {
                // OK, we wanted a "parent" ...
                return prop.parent;
            }
            if (isLocalKey(relPath, "path component", path)) {
                return resolve(prop.findLocalRaw(relPath), relPath, type,
                        executeGenerators);
            }
            final int index = relPath.indexOf(SEPATATOR);
            final String head = relPath.substring(0, index);
            // We cannot use the type here, because we are not at the end of the path.
            final Object value = resolve(prop.findLocalRaw(head), head, null,
                    executeGenerators);
            if (value == null) {
                return null;
            }
            if (value instanceof PropertiesBase) {
                prop = (PropertiesBase<TIME>) value;
                relPath = relPath.substring(index + 1);
            } else {
                throw new IllegalArgumentException("Encontered "
                        + value.getClass().getName()
                        + " while expecting a Properties");
            }
        }
    }

    /* (non-Javadoc)
     * @see com.blockwithme.properties.Properties#findRaw(java.lang.String, boolean)
     */
    @SuppressWarnings("unchecked")
    @Override
    public final <E> E findRaw(final String path,
            final boolean executeGenerators) {
        return (E) findRaw(path, null, executeGenerators);
    }

    /** Sets a property. */
    @Override
    public final void set(final String path, final Object value, final TIME when) {
        if (isLocalKey(path, "path", path)) {
            setLocalProperty(path, value, when);
        } else {
            final int index = path.lastIndexOf(SEPATATOR);
            final String ancestorPath = path.substring(0, index);
            final String localKey = path.substring(index + 1);
            @SuppressWarnings("unchecked")
            final PropertiesBase<TIME> ancestor = get(ancestorPath,
                    PropertiesBase.class);
            ancestor.setLocalProperty(localKey, value, when);
        }
    }

    /* (non-Javadoc)
     * @see com.blockwithme.properties.Properties#set(java.lang.String, java.lang.Object)
     */
    @Override
    public final void set(final String path, final Object value) {
        set(path, value, null);
    }

    /** Returns true, if this is a built-in property. */
    protected boolean builtIn(final String localKey) {
        return false;
    }

    /**
     * Returns the property value, if any. Null if absent.
     */
    protected abstract Object findLocalRaw(final String localKey);

    /** Sets a *local* property. Use null value to *remove* a property. */
    protected abstract void setLocalProperty(final String localKey,
            final Object value, final TIME when);
}
