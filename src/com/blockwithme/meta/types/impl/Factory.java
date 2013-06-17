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
package com.blockwithme.meta.types.impl;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;

import com.blockwithme.meta.types.Application;

/**
 * Create the implementations of the types package.
 * The named instances are cached, so they are only created once.
 *
 * @author monster
 */
public class Factory {

    /** The bundles. */
    private final Map<String, BundleImpl> bundles = new HashMap<String, BundleImpl>();

    /** The types. */
    private final Map<Map<BundleImpl, String>, TypeImpl> types = new HashMap<Map<BundleImpl, String>, TypeImpl>();

    /** The dependencies. */
    private final Map<Map<BundleImpl, String>, DependencyImpl> dependencies = new HashMap<Map<BundleImpl, String>, DependencyImpl>();

    /** The properties. */
    private final Map<Map<TypeImpl, String>, PropertyImpl> properties = new HashMap<Map<TypeImpl, String>, PropertyImpl>();

    /** The services. */
    private final Map<Map<BundleImpl, String>, ServiceImpl> services = new HashMap<Map<BundleImpl, String>, ServiceImpl>();

    private final Application app;

    /** A TypeBuilder */
    private final TypeBuilder typeBuilder = new TypeBuilder();

    /** Creates a pair, in form of a singleton map. */
    private <K, V> Map<K, V> pair(final K key, final V value) {
        return Collections.singletonMap(key, value);
    }

    /** Constructor */
    public Factory(final Application theApp) {
        app = Objects.requireNonNull(theApp);
    }

    /** Creates a bundle with the given name. */
    public BundleImpl bundleFor(final Class<?> clazz) {
        // TODO
        throw new UnsupportedOperationException("TODO");
    }

    /** Creates a bundle with the given name. */
    public BundleImpl bundle(final String name, final String version) {
        BundleImpl result = bundles.get(name);
        if (result == null) {
            result = new BundleImpl(app, name, version, null);
            bundles.put(name, result);
        }
        return result;
    }

    /** Creates a dependency, from the given bundle, with the given name. */
    public DependencyImpl dependency(final BundleImpl bundle, final String name) {
        final Map<BundleImpl, String> key = pair(bundle, name);
        DependencyImpl result = dependencies.get(key);
        if (result == null) {
            result = new DependencyImpl(bundle, name, null);
            dependencies.put(key, result);
        }
        return result;
    }

    /** Creates a property with the given name. */
    public PropertyImpl property(final TypeImpl type, final String name) {
        final Map<TypeImpl, String> key = pair(type, name);
        PropertyImpl result = properties.get(key);
        if (result == null) {
            result = new PropertyImpl(type, name, null);
            properties.put(key, result);
        }
        return result;
    }

    /** Creates a service, from the given bundle, with the given name. */
    public ServiceImpl service(final BundleImpl bundle, final String name) {
        final Map<BundleImpl, String> key = pair(bundle, name);
        ServiceImpl result = services.get(key);
        if (result == null) {
            result = new ServiceImpl(bundle, name, null);
            services.put(key, result);
        }
        return result;
    }

    /** Creates a type, from the given bundle, with the given name. */
    public TypeImpl type(final BundleImpl bundle, final String name) {
        final Map<BundleImpl, String> key = pair(bundle, name);
        TypeImpl result = types.get(key);
        if (result == null) {
            result = new TypeImpl(bundle, name, null);
            types.put(key, result);
        }
        return result;
    }

    /** Creates a typeRange. */
    public TypeRangeImpl typeRange(final PropertyImpl prop, final String name) {
        return new TypeRangeImpl(prop, name, null);
    }

    /** Creates a Container. */
    public ContainerImpl container(final TypeImpl type, final String name) {
        return new ContainerImpl(type, name, null);
    }

    /** Builds a type. */
    public TypeImpl buildType(final Class<?> clazz) {
        return typeBuilder.build(this, clazz);
    }
}
