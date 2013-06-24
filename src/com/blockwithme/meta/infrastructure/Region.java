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
package com.blockwithme.meta.infrastructure;

import com.blockwithme.meta.types.Named;
import com.tinkerpop.frames.Adjacency;
import com.tinkerpop.frames.annotations.gremlin.GremlinGroovy;
import com.tinkerpop.frames.annotations.gremlin.GremlinParam;
import com.tinkerpop.frames.typed.TypeValue;

/**
 * An region is a geographically distinct area on the globe, where
 * an hosting provider can have availability zones.
 *
 * We assume AvailabilityZones are statically configured...
 *
 * @author monster
 */
@TypeValue("Region")
public interface Region extends Named {
    /** Returns the availability zones in this region. */
    @Adjacency(label = "contains")
    AvailabilityZone[] getAvailabilityZones();

    /** Adds an availability Zone. */
    @Adjacency(label = "contains")
    void addAvailabilityZone(final AvailabilityZone availabilityZone);

    /** Removes an availability Zone. */
    @Adjacency(label = "contains")
    void removeAvailabilityZone(final AvailabilityZone availabilityZone);

    /** Returns the availability zone with the given name, if any. */
    @GremlinGroovy("it.out('contains').has('name',name)")
    AvailabilityZone findAvailabilityZone(
            @GremlinParam("name") final String name);
}
