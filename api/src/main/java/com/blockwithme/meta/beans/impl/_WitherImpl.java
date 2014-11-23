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
package com.blockwithme.meta.beans.impl;

import java.io.IOException;
import java.lang.reflect.Modifier;
import java.lang.reflect.UndeclaredThrowableException;
import java.util.Objects;
import java.util.logging.Logger;

import com.blockwithme.meta.Type;
import com.blockwithme.meta.beans._Wither;

/**
 * Base class for all _Wither.
 *
 * @author monster
 */
public class _WitherImpl implements _Wither {

    /** The meta type. */
    private final Type<?> metaType;

    /**
     * Lazily cached toString result (null == not computed yet)
     * Cleared automatically when the "state" of the Bean changes.
     */
    protected transient String toString;

    /** Constructor */
    public _WitherImpl(final Type<?> metaType) {
        Objects.requireNonNull(metaType, "metaType");
        // Make sure we get the "right" metaType
        final String myType = getClass().getName();
        // For "Data"/"Withers", we allow type-is-impl-and-final in addition to type-is-interface
        if (!myType.equals(metaType.type.getName())
                || !Modifier.isFinal(getClass().getModifiers())) {
            if (!myType.endsWith("Impl")) {
                throw new IllegalArgumentException("Class " + myType
                        + " should end with Impl");
            }
            final int lastDot = myType.lastIndexOf('.');
            final String myPkg = myType.substring(0, lastDot);
            if (!myPkg.endsWith(".impl")) {
                throw new IllegalArgumentException("Class " + myType
                        + " should be in package *.impl");
            }
            final int preLastDot = myPkg.lastIndexOf('.');
            final String parentPkg = myPkg.substring(0, preLastDot);
            final String myInterfaceName = parentPkg + "."
                    + myType.substring(lastDot + 1, myType.length() - 4); // "Impl".length() == 4
            if (!myInterfaceName.equals(metaType.type.getName())) {
                throw new IllegalArgumentException("Type should be "
                        + myInterfaceName + "Impl but was "
                        + metaType.type.getName());
            }
        }
        this.metaType = metaType;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.TypeOwner#getMetaType()
     */
    @Override
    public final Type<?> getMetaType() {
        return metaType;
    }

    /** Returns the Logger for this Bean */
    @Override
    public final Logger log() {
        return metaType.logger;
    }

    /** Returns the 32 bit hashcode */
    @Override
    public final int hashCode() {
        return toString().hashCode();
    }

    /** Computes the JSON representation */
    @Override
    public final void toJSON(final Appendable appendable) {
        try {
            final JacksonSerializer j = JacksonSerializer
                    .newSerializer(appendable);
            j.visit(getMetaType(), this);
            j.generator.flush();
            j.generator.close();
        } catch (final IOException e) {
            throw new UndeclaredThrowableException(e);
        }
    }

    /** Returns the String representation */
    @Override
    public final String toString() {
        if (toString == null) {
            // Use JSON format
            final StringBuilder buf = new StringBuilder(256);
            toJSON(buf);
            toString = buf.toString();
        }
        return toString;
    }

    /** Compares for equality with another object */
    @Override
    public final boolean equals(final Object obj) {
        return (obj == this)
                || ((obj != null) && (obj.getClass() == getClass())
                        && (hashCode() == obj.hashCode()) && toString().equals(
                        obj.toString()));
    }
}
