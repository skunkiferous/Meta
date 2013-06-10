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

/**
 * Defines the access-level to some type.
 *
 * The child of a private type, explicitly or by default, cannot be a public
 * type.
 *
 * @author monster
 */
public enum Access {
    /**
     * The public access level means that all dependent bundles can access
     * this type.
     */
    Public,
    /**
     * The private access level, means that only the bundle itself can access
     * this type.
     */
    Private,
    /**
     * The default access level. It means that public types (according the the
     * Java access modifier of the type) will be public (except implementations),
     * and everything else will be private (including implementations).
     */
    Default
}
