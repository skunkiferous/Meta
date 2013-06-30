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
package com.blockwithme.meta.types;

import com.tinkerpop.blueprints.Vertex;
import com.tinkerpop.frames.modules.javahandler.JavaHandlerImpl;

/**
 * @author monster
 *
 */
public abstract class TypeRange$Impl implements JavaHandlerImpl<Vertex>,
        TypeRange {

    /** Is the given type an accepted child type? */
    @Override
    public boolean accept(final Type type) {
        if (type == getDeclaredType()) {
            return true;
        }
        if (isExact()) {
            return false;
        }
        boolean accepted = false;
        for (final Type t : getAcceptedTypes()) {
            accepted = true;
            if (type == t) {
                return true;
            }
        }
        if (accepted) {
            return false;
        }
        for (final Type t : getRejectedTypes()) {
            if (type == t) {
                return false;
            }
        }
        return getDeclaredType().getType().isAssignableFrom(type.getType());
    }
}
