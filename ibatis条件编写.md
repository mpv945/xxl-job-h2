    <if test="profile == 'dev'">
        AND deleted = 0
    </if>

    <if test="profile == 'prod'">
        AND deleted = 0
        AND status = 1
    </if>

    <if test="isProd">
        AND status = 1
    </if>

<choose>
    <when test="profile == 'prod'">
        AND status = 1
    </when>

    <when test="profile == 'test'">
        AND status = 2
    </when>

    <otherwise>
        AND status = 0
    </otherwise>
</choose>

<if test="a && b || c"> ❌ 可读性差

🚀 一、null 判断（最常用）
<if test="user != null">
AND id = #{user.id}
</if>
🚀 二、空字符串判断（String）
<if test="name != null and name != ''">
AND name = #{name}
</if>
✔ 更安全写法（推荐）
<if test="name != null and name.trim() != ''">
AND name = #{name}
</if>

🚀 三、数字判断（Integer / Long）
<if test="age != null">
AND age = #{age}
</if>
✔ 判断范围
<if test="age != null and age > 18">
AND age >= 18
</if>
✔ 多条件
<if test="age != null and age >= 18 and age <= 60">
AND age BETWEEN 18 AND 60
</if>

🚀 四、List / 数组是否为空（重点）
<if test="list != null and list.size() > 0">
AND id IN
<foreach collection="list" item="id" open="(" close=")" separator=",">
#{id}
</foreach>
</if>
✔ 数组非空
<if test="array != null and array.length > 0">
AND id IN
<foreach collection="array" item="id" open="(" close=")" separator=",">
#{id}
</foreach>
</if>
🚀 五、Map 判断
<if test="params != null and params.key != null">
AND col = #{params.key}
</if>
🚀 六、Boolean 判断（isProd）
<if test="isProd">
AND status = 1
</if>
✔ 或显式写法
<if test="isProd == true">
AND status = 1
</if>
✔ 否定
<if test="!isProd">
AND status = 0
</if>
🚀 七、组合判断（复杂条件）
<if test="name != null and name != '' and age != null and age > 18">
AND name = #{name}
AND age >= 18
</if>