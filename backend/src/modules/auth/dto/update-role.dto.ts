import { IsArray, IsString } from 'class-validator';

export class UpdateRoleDto {
  @IsArray()
  @IsString({ each: true })
  roles: string[];
}
