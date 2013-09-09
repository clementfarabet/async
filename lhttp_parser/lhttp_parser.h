/*
 *  Copyright 2012 The Luvit Authors. All Rights Reserved.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

#ifndef LHTTP_PARSER
#define LHTTP_PARSER

#include <assert.h>

#include <lua.h>
#include <lauxlib.h>

#if LUA_VERSION_NUM < 502
/* lua_rawlen: Not entirely correct, but should work anyway */
#	define lua_rawlen lua_objlen
/* lua_...uservalue: Something very different, but it should get the job done */
#	define lua_getuservalue lua_getfenv
#	define lua_setuservalue lua_setfenv
#	define luaL_newlib(L,l) (lua_newtable(L), luaL_register(L,NULL,l))
#	define luaL_setfuncs(L,l,n) (assert(n==0), luaL_register(L,NULL,l))
#endif

LUALIB_API int luaopen_lhttp_parser (lua_State *L);

#endif
