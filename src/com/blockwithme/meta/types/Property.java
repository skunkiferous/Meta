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

import com.blockwithme.meta.Definition;

/**
 * Describes a property of some type.
 *
 * @author monster
 */
public interface Property extends Definition<Property> {

    /** The property name. */
    @Override
    String name();

    /** The property type range. */
    TypeRange typeRange();

    // TODO: We should have access control specifications

    /** The kinds of persistence supported by this property. */
    String[] persistence();

    // TODO ...
}
